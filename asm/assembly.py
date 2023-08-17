import sys
import re

import instructions

output_dir = '../hex/minitests/'
insts = instructions.insts

regs = {
    'x0' : 0, 'x1' : 1, 'x2' : 2, 'x3' : 3, 'x4' : 4, 'x5' : 5, 'x6' : 6, 'x7' : 7,
    'x8' : 8,
}

# from '.s' file, remove ',' and ' '.
def fileload(name):
  data = []
  with open(name, 'r', encoding='utf-8') as f:
    tmp = f.read().splitlines()
    for line in tmp:
      line = line.replace(',', '').split()
      data.append(line)
  return data

# generate hex data (per 4 byte)
def hexgen(data):
  hex = []
  for line in data:
    inst = 0
    if line[0] == 'lw' or line[0] == 'lbu' or \
       line[0] == 'jalr':
      arg2 = re.split(r'[()]', line[2])
      imm = format(int(arg2[0]) & 0xfff, '012b')
      inst = insts[line[0]] \
            | (regs[line[1]] << 7) \
            | (regs[arg2[1]] << 15) \
            | (int(imm, 2) << 20)
    elif line[0] == 'sw'or line[0] == 'sb':
      arg2 = re.split(r'[()]', line[2])
      imm = format(int(arg2[0]) & 0xfff, '012b')
      inst = insts[line[0]] \
            | (regs[line[1]] << 20) \
            | (regs[arg2[1]] << 15) \
            | (int(imm[7:12], 2) << 7) \
            | (int(imm[0:7], 2) << 25)
    elif line[0] == 'add' or line[0] == 'sub' or \
         line[0] == 'and' or line[0] == 'or'  or line[0] == 'xor' or \
         line[0] == 'sll' or line[0] == 'srl' or line[0] == 'sra' or \
         line[0] == 'slt' or line[0] == 'sltu' :
      inst = insts[line[0]] \
            | (regs[line[1]] << 7) \
            | (regs[line[2]] << 15) \
            | (regs[line[3]] << 20)
    elif line[0] == 'addi' or \
         line[0] == 'andi' or line[0] == 'ori'  or line[0] == 'xori' or \
         line[0] == 'slli' or line[0] == 'srli' or line[0] == 'srai' or \
         line[0] == 'slti' or line[0] == 'sltiu' :
      if (line[0] == 'slli' or line[0] == 'srli' or line[0] == 'srai') and int(line[3]) < 0 :
        print('Shift operation does not support negative immediates.')
        exit(1)
      inst = insts[line[0]] \
            | (regs[line[1]] << 7) \
            | (regs[line[2]] << 15) \
            | ((int(line[3]) & 0xfff) << 20)
    elif line[0] == 'beq' or line[0] == 'bne'  or line[0] == 'blt'  or \
         line[0] == 'bge' or line[0] == 'bltu' or line[0] == 'bgeu' :
      imm = format(int(line[3]) & 0xffff, '013b')[-13:]
      inst = insts[line[0]] \
            | (regs[line[1]] << 15) \
            | (regs[line[2]] << 20) \
            | (int(imm[1], 2) << 7) \
            | (int(imm[8:12], 2) << 8) \
            | (int(imm[2:8], 2) << 25) \
            | (int(imm[0], 2) << 31)
    elif line[0] == 'jal':
      imm = format(int(line[2]) & 0xffffff, '021b')[-21:]
      inst = insts[line[0]] \
            | (regs[line[1]] << 7) \
            | (int(imm[1:9], 2) << 12) \
            | (int(imm[9], 2) << 20) \
            | (int(imm[10:20], 2) << 21) \
            | (int(imm[0], 2) << 31)
    elif line[0] == 'lui' or line[0] == 'auipc':
      imm = format(int(line[2]) & 0xffffffff, '032b')
      inst = insts[line[0]] \
            | (regs[line[1]] << 7) \
            | (int(imm[0:20], 2) << 12)
    elif line[0] == 'csrrw' or line[0] == 'csrrs' or line[0] == 'csrrc':
      inst = insts[line[0]] \
            | (regs[line[1]] << 7) \
            | (regs[line[3]] << 15) \
            | (int(line[2], 16) << 20)
    elif line[0] == 'csrrwi' or line[0] == 'csrrsi' or line[0] == 'csrrci':
      if int(line[3]) < 0:
        print('{} does not support negative immediates.'.format(line[0]))
        exit(1)
      imm = format(int(line[3]), '05b')[-5:]
      inst = insts[line[0]] \
            | (regs[line[1]] << 7) \
            | (int(imm, 2) << 15) \
            | (int(line[2], 16) << 20)
    elif line[0] == 'ecall':
      inst = insts[line[0]]
    elif line[0][0:2] == '0x':
      inst = int(line[0][2:], 16)
    
    hex.append(inst)
  return hex

# main func
def main():
  if len(sys.argv) != 2:
    print('Invalid argument.')
    exit(1)

  input_file = sys.argv[1]
  data = fileload(input_file)
  print(data)

  hex = hexgen(data)

  output_file = input_file.rstrip('.s') + '.hex'

  with open(output_dir + output_file, 'w', encoding='utf-8') as f:
    for inst in hex:
      print(format(inst, '08x'))
      f.write(format(inst, '08x') + '\n')
  
  return

if __name__ == '__main__':
  main()