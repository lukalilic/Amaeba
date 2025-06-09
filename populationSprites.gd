extends Node2D

@export var Individuals: Array
@export var MainScene: PackedScene

var numberOfIndividuals = 0
var subViews = []

# GENERATOR GENA
func createRandom():
	var reflexMatrix = []
	for i in range(16):
		reflexMatrix.append(randf() - 0.5)
	return reflexMatrix

# KLASA INDIVIDUAL
class Individual extends Object:
	func _init(genes, name):
		self.genes = genes
		self.name = name
	
	var name = ""
	var genes = []
	var representation: Area2D = null
	var score = -1
	var bestScore = 0
	
	func getScore(score):
		self.score = score
		if score > self.bestScore:
			self.bestScore = score
		self.gotScore.emit(self)
	
	signal gotScore(individual: Individual)

# KOPIRANJE JEDINKE
func shallowCopy(ind):
	var new_Ind = Individual.new(ind.genes.duplicate(), ind.name + "I")
	new_Ind.bestScore = ind.bestScore
	return new_Ind

# SIGNAL: SVE JEDINKE DOBILE SKOR
func Ind_got_score(ind):
	for i in Individuals:
		if i.score < 0:
			return
	newGeneration()

# SELEKCIJA: najbolji uvek preživi + nasumični odabrani
func select(population):
	population.sort_custom(func(ind1, ind2): return ind1.score > ind2.score)
	var chosen = []
	chosen.append(population[0])  # najbolji
	while chosen.size() < int(len(population) / 2):
		var candidate = population[randi_range(1, len(population) / 2)]
		if not candidate in chosen:
			chosen.append(candidate)
	return chosen

# UKRŠTANJE: koristi više metoda kombinovanja gena
func cross(population):
	var children = []
	for p in population:
		children.append(shallowCopy(p))  # roditelji ostaju

	while children.size() < subViews.size():
		var parent1 = population[randi_range(0, population.size() - 1)]
		var parent2 = population[randi_range(0, population.size() - 1)]
		var child_genes = []

		for i in range(16):
			var method = randi_range(0, 2)
			if method == 0:
				child_genes.append(randf() < 0.5 ? parent1.genes[i] : parent2.genes[i])
			elif method == 1:
				child_genes.append((parent1.genes[i] + parent2.genes[i]) / 2.0)
			else:
				child_genes.append(i < 8 ? parent1.genes[i] : parent2.genes[i])

		var child = Individual.new(child_genes, "C" + str(numberOfIndividuals))
		numberOfIndividuals += 1
		children.append(child)

	return children

# MUTACIJA: više jedinki, nasumične promene gena
func mutate(population):
	for i in population:
		if randf() < 0.3:
			var index = randi_range(0, 15)
			i.genes[index] = randf() - 0.5
			i.name += "M"
	return population

# NOVA GENERACIJA
func newGeneration():
	var population = []
	Individuals.sort_custom(func(ind1, ind2): return ind1.score > ind2.score)
	for i in Individuals:
		population.append(shallowCopy(i))

	population = select(population)
	population = cross(population)
	population = mutate(population)

	if population.size() > subViews.size():
		population = population.slice(0, subViews.size())

	reset(population)

# RESETUJ SCENU
func reset(population):
	for v in subViews:
		for n in v.get_children():
			v.remove_child(n)
			n.queue_free()

	Individuals = []
	for i in range(len(subViews)):
		var ms = MainScene.instantiate()
		var ind = population[i]
		ind.representation = ms
		Individuals.append(ind)
		ind.gotScore.connect(Ind_got_score)
		ms.reflexMatrix = ind.genes
		ms.gameover.connect(ind.getScore)
		ms.NameLabel = ind.name
		ms.BestScore = ind.bestScore
		subViews[i].add_child(ms)

# START
func _ready():
	seed(43)
	subViews = []
	var gridchildren = $GridContainer.get_children()
	for g in gridchildren:
		subViews.append(g.get_child(0))

	var population = []
	for i in range(subViews.size()):
		population.append(Individual.new(createRandom(), "{" + str(i) + "}"))
		numberOfIndividuals += 1
	reset(population)

func _process(delta):
	pass
