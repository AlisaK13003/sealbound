extends Node

class_name genetic_algorithm

var population_size = 10
var generation_count = 50
var mutation_rate = 0.3
var cross_over_rate = 0.7

var total_number_of_weights = 8
var per_weight_mutation_weight = 1.0 / total_number_of_weights
var sigma = 0.1

var hall_of_fame = []

var healing_weight = 10
var kill_weight = 50
var damage_importance_weight = 10
var healing_importance_weight = 10
var remove_status_weight = 15
var give_self_status_weight = 15
var remove_players_status_weight = 20
var give_player_status_weight = 20

@onready var rng = RandomNumberGenerator.new()
var weight_range_lower = 0
var weight_range_upper = 10

@onready var training_grounds: Node

var population: Array[population_member]

var tournament_size = 5

class population_member:
	var fitness
	var member
	var total_weight_count
	var weight_range_lower
	var weight_range_upper
	var already_evaluated
	var rng
	func _init(total_weight_count, weight_range_lower, weight_range_upper, rng):
		fitness = 0
		self.total_weight_count = total_weight_count
		self.weight_range_lower = weight_range_lower
		self.weight_range_upper = weight_range_upper
		self.rng = rng
		self.already_evaluated = false
		member = create_individual()

	func create_individual():
		var individual = []
		for i in range(total_weight_count):
			individual.append(rng.randf_range(weight_range_lower, weight_range_upper))
		return individual

func fitness_function(individual):
	var results = await training_grounds.battle_loop(individual.member)
	individual.already_evaluated = true
	var number_of_killed_players = results[0]
	var number_of_killed_enemies = results[1]
	var player_container = results[2]
	var highest_wave_reached = results[3]
	var number_of_possible_waves = results[4]
	var cum_health = results[5]
	
	#var average_remaining_player_health = 0.0
	#for player in player_container.get_children():
	#	average_remaining_player_health += player.stored_combatant.combatant_stats.health
	#average_remaining_player_health = float(average_remaining_player_health) / 3.0
	
	return cum_health

func run_crossover(ind_1, ind_2):
	var rand_point = rng.randi_range(0, total_number_of_weights)
	var child_1 = []
	var child_2 = []
	for i in range(total_number_of_weights):
		var chance = rng.randf_range(0, 1)
		child_1.append(chance * ind_1.member[i] + (1 - chance) * ind_2.member[i])
		child_2.append((1 - chance) * ind_1.member[i] + chance * ind_2.member[i])

	var ret_kid_1 = population_member.new(total_number_of_weights, weight_range_lower, weight_range_upper, rng)
	var ret_kid_2 = population_member.new(total_number_of_weights, weight_range_lower, weight_range_upper, rng)

	ret_kid_1.member = child_1
	ret_kid_2.member = child_2

	return [ret_kid_1, ret_kid_2]
	
func gaussian_mutation(individual, mutation_rate, sigma, low_bound, up_bound):
	var ind_to_test = individual.member.duplicate()
	for i in range(ind_to_test.size()):
		if rng.randf() < mutation_rate:
			var nudge = rng.randfn(0, sigma)

			var new_val = ind_to_test[i] + nudge

			if new_val < weight_range_lower:
				new_val = weight_range_lower
			elif new_val > weight_range_upper:
				new_val = weight_range_upper
			ind_to_test[i] = new_val
	
	var ret_kid_1 = population_member.new(total_number_of_weights, weight_range_lower, weight_range_upper, rng)
	ret_kid_1.member = ind_to_test
	
	return ret_kid_1

func perform_selection(pop):
	var selected_individuals: Array[population_member] = []
	for i in range(tournament_size):
		selected_individuals.append(pop[rng.randi_range(0, pop.size() - 1)])

	return sort_by_fitness(selected_individuals)[0]
	
func sort_by_fitness(fitness_people: Array[population_member]):
	fitness_people.sort_custom(func(a, b):
		return a.fitness < b.fitness
	)
	return fitness_people

func main_loop():
	for i in range(generation_count):
		print("GENERATION: ", i)
		for j in range(population.size()):
			if not population[j].already_evaluated:
				await training_grounds._reset()
				population[j].fitness = await fitness_function(population[j])
				print(population[j].fitness, " fitness and model ", population[j].member)
			
		#selection
		var selected_individuals: Array[population_member] = []
		for k in range(population_size / tournament_size):
			selected_individuals.append(perform_selection(population))
			
		var children_population: Array[population_member] = []
		
		# Elitism
		var sorted_pop = sort_by_fitness(population)
		var elite_count = 1
		for k in range(elite_count):
			children_population.append(sorted_pop[k])
		
		var chance = 0

		for ind in selected_individuals:
			for ind2 in selected_individuals:
				if ind.member == ind2.member:
					continue
				chance = rng.randf_range(0, 1)
				if chance < cross_over_rate:
					var crossover = run_crossover(ind, ind2)
					children_population.append(crossover[0])
					children_population.append(crossover[1])
					
		for mutant in selected_individuals:
			chance = rng.randf_range(0, 1)
			if chance < mutation_rate:
				children_population.append(gaussian_mutation(mutant, mutation_rate, sigma, weight_range_lower, weight_range_upper))
		
		for child in children_population:
			await training_grounds._reset()

			child.fitness = await fitness_function(child)
		
		population = sort_by_fitness(children_population)
		while (population.size() > population_size):
			population.pop_back()
			
		print("CURRENT BEST MEMBER: ", sort_by_fitness(population)[0].member)
		print()
		print()
	
func _setup(t_ground):
	training_grounds = t_ground
	for i in range(population_size):
		population.append(population_member.new(total_number_of_weights, weight_range_lower, weight_range_upper, rng))
	await main_loop()
