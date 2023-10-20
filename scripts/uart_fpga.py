import serial
import sys
import time


def serial_init(portUSB: str, baudRate: int, parity: str, stopBits: int, byteSize: int) -> serial.Serial:
    #ser = serial.serial_for_url('loop://', timeout=1)
    ser = serial.Serial(port='/dev/ttyUSB{}'.format(int(portUSB)), baudrate = baudRate, 
                        parity=parity, stopbits = stopBits, bytesize=byteSize)
    ser.isOpen()
    ser.timeout = None
    ser.flushInput()
    ser.flushOutput()

    return ser


def send_frame(ser: serial.Serial, op: int, data: list[str]) -> int:
    byte_v = []
    byte_v.append(0xA5)

    print(data)

    try:
        a = int(data[0], base=16)
        b = int(data[1], base=16)
    except Exception as e:
        print("Error: Invalid operand.")
        print(e)
        return -1
    
    for i in range(4):
        byte_v.append((a >> 8*i) & 0xFF)
    
    for i in range(4):
        byte_v.append((b >> 8*i) & 0xFF)

    byte_v.append(op)
    byte_v.append(0xF5)

    print('>> Sending:')
    print('>> ' + str(list(map(lambda x: hex(x), byte_v))))

    for ptr in range(len(byte_v)):
        try:
            if byte_v[ptr] < 0:
                ser.write(byte_v[ptr].to_bytes(1, byteorder='little', signed=True))
            else:
                ser.write(byte_v[ptr].to_bytes(1, byteorder='little', signed=False))
        except Exception as e:
            print("Error: Couldn't load data in write buffer")
            print(e)
            return -1
    
    return 0


def receive_frame(ser: serial.Serial):
    out = []
    while ser.inWaiting() > 0:
        out.append(ser.read(1))
    if len(out) != 0:
        print(">> Received Bytes:")
        print(">> " + str(out))
        print(">> " + str(list(map(lambda x: x.hex(), out))))
    
    r = 0
    for i in range(4):
        r = r + (int.from_bytes(out[i], byteorder='little') << i*8)
    
    print('result:')
    print(f'{r:#x}')
    


def parse_line(data: str) -> (int, list[str]):
    if ((pos := data.find('<<')) != -1):
        op = 0x00
        data = data.split('<<')
    elif ((pos := data.find('>>')) != -1):
        op = 0x02
        data = data.split('>>')
    elif ((pos := data.find('>>>')) != -1):
        op = 0x03
        data = data.split('>>>')
    elif ((pos := data.find('+')) != -1):
        op = 0x20
        data = data.split('+')
    elif ((pos := data.find(' - ')) != -1):
        op = 0x22
        data = data.split(' - ')
    elif ((pos := data.find('&')) != -1):
        op = 0x24
        data = data.split('&')
    elif ((pos := data.find('and')) != -1):
        op = 0x24
        data = data.split('and')
    elif ((pos := data.find('|')) != -1):
        op = 0x25
        data = data.split('|')
    elif ((pos := data.find('xor')) != -1):
        op = 0x26
        data = data.split('xor')
    elif ((pos := data.find('or')) != -1):
        op = 0x25
        data = data.split('or')
    elif ((pos := data.find('^')) != -1):
        op = 0x26
        data = data.split('^')
    elif ((pos := data.find('nor')) != -1):
        op = 0x27
        data = data.split('nor')
    elif (((pos := data.find('slt')) != -1) and ((pos := data.find('-')) != -1)):
        op = 0x2A
        data = data.split(' ')
        data = data[-2:]
    elif (((pos := data.find('slt')) != -1)):
        op = 0x2B
        data = data.split(' ')
        data = data[-2:]
    else:
        op = 0xFF
        data = None
    
    return op, data 


def send_command(ser: serial.Serial, data: str):
    op, data = parse_line(data)
    if op == 0xFF:
        print('Invalid operator')
        return
    ret = send_frame(ser, op, data)
    if ret == 0:
        time.sleep(2)
        receive_frame(ser)


def run(ser: serial.Serial):
    while 1 :
        data = input("ToSent: ")
        if data == 'exit':
            if ser.isOpen():
                ser.close()
            break
        else:
            send_command(ser, data)


def main():
    portUSB = sys.argv[1]
    baudrate = int(sys.argv[2])
    parity = serial.PARITY_NONE
    stopbits = serial.STOPBITS_ONE
    bytesize = serial.EIGHTBITS
    
    ser = serial_init(portUSB, baudrate, parity, stopbits, bytesize)
    run(ser)


if __name__ == "__main__":
    main()