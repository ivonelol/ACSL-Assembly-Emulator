module main

import os
import readline { read_line }

const opcodes = [
	'LOAD',
	'STORE',
	'ADD',
	'SUB',
	'MULT',
	'DIV',
	'BG',
	'BE',
	'BL',
	'BU',
	'READ',
	'PRINT',
	'DC',
	'END',
]

struct Instruction {
	label  string
	opcode string
	loc    string
}

struct Program {
	labels       map[string]int
	instructions []Instruction
mut:
	ctx map[string]int
}

fn main() {
	filename := os.args[1] or { panic('no file provided') }
	lines := os.read_lines(filename) or { panic('cannot read file ${filename}') }
	mut program := parse_program(lines)
	evaluate_program(mut program)
	println(program.ctx)
}

fn parse_program(lines []string) Program {
	mut labels := map[string]int{}
	mut instructions := []Instruction{}

	for i, line in lines {
		if line == '' {
			continue
		}
		tokens := line.split(' ')
		if tokens.len > 3 {
			panic('too many tokens in line ${i}')
		}
		if tokens[0] !in opcodes {
			label := tokens[0]
			opcode := tokens[1]
			loc := tokens[2] or { '' }
			instruction := Instruction{
				label: label
				opcode: opcode
				loc: loc
			}
			instructions << instruction
			labels[label] = i
		} else {
			opcode := tokens[0]
			loc := tokens[1] or { '' }
			instruction := Instruction{
				opcode: opcode
				loc: loc
			}
			instructions << instruction
		}
	}

	return Program{
		labels: labels
		instructions: instructions
	}
}

fn evaluate_program(mut program Program) {
	mut pc := 0
	for pc < program.instructions.len {
		instruction := program.instructions[pc]
		mut locv := 0
		if instruction.loc != '' && instruction.loc[0] == 61 {
			locv = instruction.loc[1..].int()
		} else {
			locv = program.ctx[instruction.loc]
		}

		match instruction.opcode {
			'LOAD' {
				program.ctx['ACC'] = locv
			}
			'STORE' {
				program.ctx[instruction.loc] = program.ctx['ACC']
			}
			'ADD' {
				program.ctx['ACC'] += locv
				program.ctx['ACC'] %= 1_000_000
			}
			'SUB' {
				program.ctx['ACC'] -= locv
				program.ctx['ACC'] %= 1_000_000
			}
			'MULT' {
				program.ctx['ACC'] *= locv
				program.ctx['ACC'] %= 1_000_000
			}
			'DIV' {
				program.ctx['ACC'] /= locv
				program.ctx['ACC'] %= 1_000_000
			}
			'BG' {
				if program.ctx['ACC'] > 0 {
					pc = program.labels[instruction.loc]
					continue
				}
			}
			'BE' {
				if program.ctx['ACC'] == 0 {
					pc = program.labels[instruction.loc]
					continue
				}
			}
			'BL' {
				if program.ctx['ACC'] < 0 {
					pc = program.labels[instruction.loc]
					continue
				}
			}
			'BU' {
				pc = program.labels[instruction.loc]
				continue
			}
			'READ' {
				input := read_line('') or { panic('cannot parse input') }
				program.ctx[instruction.loc] = input.int()
			}
			'PRINT' {
				println(program.ctx[instruction.loc])
			}
			'DC' {
				program.ctx[instruction.label] = instruction.loc.int()
			}
			'END' {
				return
			}
			else {
				panic('unknown opcode ${instruction.opcode} in line ${pc}')
			}
		}

		pc++
	}
}
