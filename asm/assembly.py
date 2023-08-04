import sys
import re

import instructions

output_dir = '../hex/'
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
    if line[0] == 'lw':
      arg2 = re.split(r'[()]', line[2])
      inst = insts[line[0]] \
            | (regs[line[1]] << 7) \
            | (regs[arg2[1]] << 15) \
            | (int(arg2[0]) << 20)
    elif line[0] == 'sw':
      arg2 = re.split(r'[()]', line[2])
      imm = format(int(arg2[0]), '012b')
      inst = insts[line[0]] \
            | (regs[line[1]] << 20) \
            | (regs[arg2[1]] << 15) \
            | (int(imm[7:12], 2) << 7) \
            | (int(imm[0:7], 2) << 25)
    elif line[0] == 'add' or line[0] == 'sub' or \
         line[0] == 'and' or line[0] == 'or'  or line[0] == 'xor' or \
         line[0] == 'sll' or line[0] == 'srl' or line[0] == 'sra' :
      inst = insts[line[0]] \
            | (regs[line[1]] << 7) \
            | (regs[line[2]] << 15) \
            | (regs[line[3]] << 20)
    elif line[0] == 'addi' or \
         line[0] == 'andi' or line[0] == 'ori'  or line[0] == 'xori' or \
         line[0] == 'slli' or line[0] == 'srli' or line[0] == 'srai':
      inst = insts[line[0]] \
            | (regs[line[1]] << 7) \
            | (regs[line[2]] << 15) \
            | (int(line[3]) << 20)
    elif line[0][0:2] == '0x':
      inst = int(line[0][2:], 16)
    
    hex.append(inst)
  return hex

# main func
def main():
  if len(sys.argv) != 2:
    print('invalid argument.')
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