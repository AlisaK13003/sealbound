extends Node

var entire_party : Array[PartyMember]

var party_slot_1 : PartyMember
var party_slot_2 : PartyMember
var party_slot_3 : PartyMember

var current_location: String = "[Forest Dungeon: Floor 1]"
var previous_coordinates : Vector2

var item_list : Array[Items]

var current_encounter : encounters
