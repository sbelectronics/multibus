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

#define PIN_RESIN 8
#define PIN_XACK 9
#define PIN_WAIT 10
#define PIN_HRESET 11
#define PIN_STB 13
#define PIN_IOR 14
#define PIN_IOW 15
#define PIN_XCY 24
#define PIN_OVRD 25
#define PIN_RSTB 26
#define PIN_BCR1 27

#define PIN_A0 4
#define PIN_A1 5
#define PIN_A2 6
#define PIN_A3 7

#define REG_BUSR 0
#define REG_BUSW 1
#define REG_LATAL 2
#define REG_LATAH 3
#define REG_READ_PENDING 4
#define REG_RESET_PENDING 5
#define REG_READ_RESREQ 6
#define REG_RESET_RESREQ 7
#define REG_MR0 8
#define REG_MR1 9
#define REG_MR2 0xA
#define REG_MR3 0xB
#define REG_MW0 0xC
#define REG_MW1 0xD
#define REG_MW2 0xE
#define REG_MW3 0xF


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
    int dv = 400 * delayMult;

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

static void _select(uint16_t addr)
{
  uint32_t data = (addr & 0x0F) << 4;

  gpioWrite_Bits_0_31_Clear(0x000000F0);
  gpioWrite_Bits_0_31_Set(data);
}

static void _stb_down()
{
  gpioWrite(PIN_STB, 0);
}

static void _stb_up()
{
  gpioWrite(PIN_STB, 1);
}

static void _wait_for_xack()
{
  while (gpioRead(PIN_XACK) == 1) {
    ;
  }
}

static uint16_t _data_read()
{
  uint32_t data = gpioRead_Bits_0_31();
  return ((data >> 16) & 0xFF);
}

static void _data_write(uint16_t val)
{
  uint32_t data = (val & 0xFF) << 16;

  gpioWrite_Bits_0_31_Clear(0x00FF0000);
  gpioWrite_Bits_0_31_Set(data);
}

static uint16_t _data_read_inverted()
{
  return (~_data_read()) & 0xFF;
}

static void _data_write_inverted(uint16_t val)
{
  _data_write((~val) & 0xFF);
}

static uint16_t _read_mbox(uint16_t addr)
{
  uint16_t v;
  _select(REG_MR0 + addr);
  short_delay();
  _stb_down();
  medium_delay();
  v = _data_read();
  _stb_up();
  return v;
}

static void _write_mbox(uint16_t addr, uint16_t val)
{
  _databus_config_write();
  _data_write(val);
  _select(REG_MW0 + addr);
  short_delay();
  _stb_down();
  medium_delay();
  _stb_up();
  _databus_config_read();
}

static uint16_t _read_pending()
{
  uint16_t v;
  _select(REG_READ_PENDING);
  short_delay();
  _stb_down();
  medium_delay();
  v = _data_read();
  _stb_up();
  return (v & 1);
}

static void _reset_pending()
{
  _select(REG_RESET_PENDING);
  short_delay();
  _stb_down();
  medium_delay();
  _stb_up();
}

static void _write_addr_high(uint16_t addr)
{
  _databus_config_write();
  _data_write_inverted((addr >> 8) & 0xFF);
  _select(REG_LATAH);
  short_delay();
  _stb_down();
  medium_delay();
  _stb_up();
  _databus_config_read();
}

static void _write_addr_low(uint16_t addr)
{
  _databus_config_write();
  _data_write_inverted(addr & 0xFF);
  _select(REG_LATAL);
  short_delay();
  _stb_down();
  medium_delay();
  _stb_up();
  _databus_config_read();
}

static void _write_mem(uint16_t val)
{
  _databus_config_write();
  _data_write_inverted(val);
  _select(REG_BUSW);
  short_delay();
  _stb_down();
  _wait_for_xack();
  _stb_up();
  _databus_config_read();
}

static uint16_t _read_mem()
{
  uint16_t v;
  _select(REG_BUSR);
  short_delay();
  _stb_down();
  _wait_for_xack();
  v = _data_read_inverted();
  _stb_up();
  return v;
}

static PyObject *diskdirect_init(PyObject *self, PyObject *args)
{
  if (gpioInitialise() < 0) {
    Py_RETURN_FALSE;
  }

  _databus_config_read();                   // configure data buffers for read

  delayMult = 1;

  Py_RETURN_TRUE;
}

static PyObject *diskdirect_cleanup(PyObject *self, PyObject *args)
{
  gpioTerminate();
  Py_RETURN_TRUE;
}

static PyObject *diskdirect_clk_delay(PyObject *self, PyObject *args)
{
  medium_delay();
  Py_RETURN_NONE;
}

static PyObject *diskdirect_read_mbox(PyObject *self, PyObject *args)
{
  uint16_t addr, val;

  if (!PyArg_ParseTuple(args, "H", &addr)) {
    return NULL;
  }

  val = _read_mbox(addr);

  return Py_BuildValue("H", val);
}

static PyObject *diskdirect_write_mbox(PyObject *self, PyObject *args)
{
  uint16_t addr, val;

  if (!PyArg_ParseTuple(args, "HH", &addr, &val)) {
    return NULL;
  }

  _write_mbox(addr, val);

  return Py_BuildValue("");
}

static PyObject *diskdirect_delay_mult(PyObject *self, PyObject *args)
{
  uint16_t val;

  if (!PyArg_ParseTuple(args, "H", &val)) {
    return NULL;
  }

  delayMult = val;

  return Py_BuildValue("");
}

static PyObject *diskdirect_read_pending(PyObject *self, PyObject *args)
{
  uint16_t val;

  val = _read_pending();

  return Py_BuildValue("H", val);
}

static PyObject *diskdirect_reset_pending(PyObject *self, PyObject *args)
{
  _reset_pending();

  Py_RETURN_NONE;
}

static PyObject *diskdirect_write_mem(PyObject *self, PyObject *args)
{
  uint16_t addr, val;

  if (!PyArg_ParseTuple(args, "HH", &addr, &val)) {
    return NULL;
  }

  _write_addr_high(addr >> 8);
  _write_addr_low(addr & 0xFF);
  _write_mem(val);

  return Py_BuildValue("");
}

static PyObject *diskdirect_read_mem(PyObject *self, PyObject *args)
{
  uint16_t addr, val;

  if (!PyArg_ParseTuple(args, "H", &addr)) {
    return NULL;
  }

  _write_addr_high(addr >> 8);
  _write_addr_low(addr & 0xFF);
  val = _read_mem(val);

  return Py_BuildValue("H", val);
}

static PyMethodDef diskdirect_methods[] = {
  {"init", diskdirect_init, METH_VARARGS, "Initialize"},
  {"cleanup", diskdirect_cleanup, METH_VARARGS, "Cleanup"},
  {"read_mbox", diskdirect_read_mbox, METH_VARARGS, "read mbox"},
  {"write_mbox", diskdirect_write_mbox, METH_VARARGS, "write mbox"},
  {"delay_mult", diskdirect_delay_mult, METH_VARARGS, "set delay mult"}, 
  {"clk_delay", diskdirect_clk_delay, METH_VARARGS, "clock delay"},
  {"read_pending", diskdirect_read_pending, METH_VARARGS, "read prending flag"},
  {"reset_pending", diskdirect_reset_pending, METH_VARARGS, "reset prending flag"},
  {"read_mem", diskdirect_read_mbox, METH_VARARGS, "read memory"},
  {"write_mem", diskdirect_write_mbox, METH_VARARGS, "write memory"},  
  {NULL, NULL, 0, NULL}
};

static struct PyModuleDef diskdirect_module =
{
    PyModuleDef_HEAD_INIT,
    "diskdirect_ext", /* name of module */
    "",          /* module documentation, may be NULL */
    -1,          /* size of per-interpreter state of the module, or -1 if the module keeps state in global variables. */
   diskdirect_methods
};

PyMODINIT_FUNC PyInit_diskdirect_ext(void)
{
  return PyModule_Create(&diskdirect_module);
}
