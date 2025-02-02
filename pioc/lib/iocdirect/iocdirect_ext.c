#include <Python.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <pigpio.h>

#define PIN_D0 16
#define PIN_D1 17
#define PIN_D2 18
#define PIN_D3 19
#define PIN_D4 20
#define PIN_D5 21
#define PIN_D6 22
#define PIN_D7 23
#define PIN_INIT 27
#define PIN_SELDBOUT 24
#define PIN_SELDBIN 25
#define PIN_SELSTAT 26
#define PIN_INT 4
#define PIN_A0 5
#define PIN_CLKF0 6
#define PIN_SETF1 12
#define PIN_RESETF1 13

#define PIN_HRESET 7
#define PIN_RESIN 8

#define FLAG_OBF 1
#define FLAG_IBF 2
#define FLAG_F0 4
#define FLAG_CD 8

#define REG_NONE 0
#define REG_DBOUT 1
#define REG_DBIN 2
#define REG_STAT 3

static int datapins[] = {PIN_D0, PIN_D1, PIN_D2, PIN_D3,
                         PIN_D4, PIN_D5, PIN_D6, PIN_D7};
uint16_t isTaken;
uint16_t delayMult;
uint16_t lastHiAddr;
uint16_t lastHiAddrSet;

void short_delay(void)
{
    int j;

    for (j=0; j<50; j++) {
        asm("nop");
    }
}

void medium_delay(void)
{
    int j;
    int dv = 200 * delayMult;

    for (j=0; j<dv; j++) {
        asm("nop");
    }
}

static void _databus_config_read()
{
  for (int i=0; i<8; i++) {
    gpioSetMode(datapins[i], PI_INPUT);
  }
}

static void _databus_config_write()
{
  for (int i=0; i<8; i++) {
    gpioSetMode(datapins[i], PI_OUTPUT);
  }
}

static void _select(uint16_t reg)
{
  gpioWrite(PIN_SELDBOUT, reg == REG_DBOUT ? 0 : 1);
  gpioWrite(PIN_SELDBIN, reg == REG_DBIN ? 0 : 1);
  gpioWrite(PIN_SELSTAT, reg == REG_STAT ? 0 : 1);
}

static uint16_t _data_read()
{
  uint32_t data = gpioRead_Bits_0_31();
  return (~((data >> 16)) & 0xFF);
}

static void _data_write(uint16_t val)
{
  uint32_t data = ((~val) & 0xFF) << 16;

  gpioWrite_Bits_0_31_Clear(0x00FF0000);
  gpioWrite_Bits_0_31_Set(data);
}

static uint16_t _read_flags()
{
  uint16_t lastResult = 0xFFFF;
  uint16_t result;

  _select(REG_STAT);
  short_delay();
  while (1) {
    // be wary of catching the flags in a transient state
    // maybe we get the IBF while the C/D is still settling...
    result = _data_read();
    if (result == lastResult) {
      break;
    }
    lastResult = result;
  }
  _select(REG_NONE);
  return result;
}

static uint16_t _read_dbin()
{
  uint16_t v;
  _select(REG_DBIN);
  short_delay();
  v = _data_read();
  _select(REG_NONE);
  return v;
}

static void _write_dbout(uint16_t val)
{
  _select(REG_NONE);
  _databus_config_write();
  _data_write(val);
  short_delay();
  _select(REG_DBOUT);
  short_delay();
  _select(REG_NONE);
  _databus_config_read();
}

static PyObject *iocdirect_init(PyObject *self, PyObject *args)
{
  if (gpioInitialise() < 0) {
    Py_RETURN_FALSE;
  }

  _databus_config_read();                   // configure data buffers for read

  delayMult = 1;

  Py_RETURN_TRUE;
}

static PyObject *iocdirect_cleanup(PyObject *self, PyObject *args)
{
  gpioTerminate();
  Py_RETURN_TRUE;
}

static PyObject *iocdirect_clk_delay(PyObject *self, PyObject *args)
{
  medium_delay();
  Py_RETURN_NONE;
}

static PyObject *iocdirect_read_flags(PyObject *self, PyObject *args)
{
  uint16_t val;

  val = _read_flags();

  return Py_BuildValue("H", val);
}

static PyObject *iocdirect_read_dbin(PyObject *self, PyObject *args)
{
  uint16_t val;

  val = _read_dbin();

  return Py_BuildValue("H", val);
}

static PyObject *iocdirect_write_dbout(PyObject *self, PyObject *args)
{
  uint16_t val;

  if (!PyArg_ParseTuple(args, "H", &val)) {
    return NULL;
  }

  _write_dbout(val);

  return Py_BuildValue("");
}

static PyObject *iocdirect_delay_mult(PyObject *self, PyObject *args)
{
  uint16_t val;

  if (!PyArg_ParseTuple(args, "H", &val)) {
    return NULL;
  }

  delayMult = val;

  return Py_BuildValue("");
}

static PyMethodDef iocdirect_methods[] = {
  {"init", iocdirect_init, METH_VARARGS, "Initialize"},
  {"cleanup", iocdirect_cleanup, METH_VARARGS, "Cleanup"},
  {"read_flags", iocdirect_read_flags, METH_VARARGS, "read flags"},
  {"read_dbin", iocdirect_read_dbin, METH_VARARGS, "read data in"},
  {"write_dbout", iocdirect_write_dbout, METH_VARARGS, "write data out"},
  {"delay_mult", iocdirect_delay_mult, METH_VARARGS, "set delay mult"}, 
  {"clk_delay", iocdirect_clk_delay, METH_VARARGS, "clock delay"},
  {NULL, NULL, 0, NULL}
};

static struct PyModuleDef iocdirect_module =
{
    PyModuleDef_HEAD_INIT,
    "iocdirect_ext", /* name of module */
    "",          /* module documentation, may be NULL */
    -1,          /* size of per-interpreter state of the module, or -1 if the module keeps state in global variables. */
   iocdirect_methods
};

PyMODINIT_FUNC PyInit_iocdirect_ext(void)
{
  return PyModule_Create(&iocdirect_module);
}
