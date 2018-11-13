import Foundation


enum attackStyle{
	case controlled
	case aggressive
	case defensive
	case accurate
}
class player {

	let name: String!
	var pid: UInt16!
	var health: Int!

	let constitution: Int!
	let attack: Int!
	let strength: Int!
	let defence: Int!
	let style: attackStyle!

	let atkBonus: Int!
	let defBonus: Int!
	let strBonus: Int!

	func atkRoll() -> Int {
		var eLevel = attack + 8
		if style == .accurate { eLevel += 3 }
		else if style == .controlled { eLevel += 1 }
		return eLevel * (atkBonus + 64)
	}

	func defRoll() -> Int {
		var eLevel = defence + 8
		if style == .defensive { eLevel += 3 }
		else if style == .controlled { eLevel += 1 }
		return eLevel * (defBonus + 64)
	}

	func maxhit() -> Int{
		var eLevel = strBonus + 8
		if style == .aggressive { eLevel += 3 }
		else if style == .controlled { eLevel += 1 }
		let maxhit = (Double(strBonus * eLevel) / 640) + (Double(strBonus) / 80) + (Double(eLevel) / 10) + 1.3
		return Int(floor(maxhit))
	}

	func deductHP(_ hitsplat: Int) -> Bool{
		health -= hitsplat
		return health > 0
	}


	func reset(){
		health = self.constitution
		updatePid()
	}

	func updatePid(){
		pid = UInt16.random(in: 0...UInt16.max)
	}




	init(health: Int, attack: Int, strength: Int, defence: Int, style: attackStyle, atkBonus: Int, defBonus: Int, strBonus: Int, name: String) {

		self.health = health

		self.constitution = health
		self.attack = attack
		self.strength = strength
		self.defence = defence
		self.style = style

		self.atkBonus = atkBonus
		self.defBonus = defBonus
		self.strBonus = strBonus
		self.name = name
		self.pid = UInt16.random(in: 0...UInt16.max)
	}
}


var HAIL69HYDRA = player(health: 92, attack: 95, strength: 98, defence: 70, style: .accurate, atkBonus: 82, defBonus: 0, strBonus: 82, name: "HAIL69HYDRA")
var mauler9 = player(health: 98, attack: 99, strength: 99, defence: 69, style: .aggressive, atkBonus: 90, defBonus: 0, strBonus: 86, name: "mauler9")

//let a = HAIL69HYDRA.atkRoll()//HH attacking mauler
//let b = mauler9.defRoll()
//
//let c = mauler9.atkRoll()//mauler attacking HH
//let d = HAIL69HYDRA.defRoll()

func accuracy(_ atk: Double, _ def: Double) -> Double{
	if atk > def {
		return 1.0 - ((def + 2) / (2 * (atk + 1)))
	}
	else if atk < def{
		return atk / (2 * (def + 1))
	}
	else{
		return atk / (2 * (def + 1))
	}
}


func duel(player1: player, player2: player) -> player{

	let p1Acc = accuracy(Double(player1.atkRoll()), Double(player2.defRoll()))
	let p2Acc = accuracy(Double(player2.atkRoll()), Double(player1.defRoll()))

	let p1Max = player1.maxhit()
	let p2Max = player2.maxhit()

	var round = 0
	while player1.health > 0 && player2.health > 0 {
		let p1Roll = Double.random(in: 0...1)
		let p2Roll = Double.random(in: 0...1)
		if p1Roll < p1Acc{
			let hitsplat = Int.random(in: 0...p1Max)
			player2.deductHP(hitsplat)
		}
		if p2Roll < p2Acc{
			let hitsplat = Int.random(in: 0...p2Max)
			player1.deductHP(hitsplat)
		}
		round += 1
	}
	if player1.health <= 0 && player2.health <= 0{
		return player1.pid < player2.pid ? player1 : player2
	}
	return player2.health > 0 ? player2 : player1
}


//print(duel(player1: HAIL69HYDRA, player2: mauler9).name)

let maxMain1 = player(health: 99, attack: 99, strength: 99, defence: 99, style: .accurate, atkBonus: 90, defBonus: 0, strBonus: 86, name: "mm1")
let maxMain2 = player(health: 99, attack: 99, strength: 99, defence: 99, style: .accurate, atkBonus: 90, defBonus: 0, strBonus: 86, name: "mm2")
var l = 0

for _ in 0...10000000{
	if duel(player1: maxMain1, player2: maxMain2).name == "mm1" { l+=1 }
	maxMain1.reset()
	maxMain2.reset()
}
print(l)
