#lang dssl2

struct ingredient:
    let name: str?
    let quantity: num?
    let unit: str?

class Recipe:
    let name: str?
    let ingredients: VecC[ingredient?]
    let steps: VecC[str?]

    # Constructor
    def __init__(self, name, ingredients):
        self.name = name
        self.ingredients = ingredients
        self.steps = []

    def add_step(self, new_step):
        # Once created, vectors are of fixed size!
        let new_steps = [None; self.steps.len() + 1]
        for i, step in self.steps:
            new_steps[i] = step
        new_steps[self.steps.len()] = new_step
        self.steps = new_steps

    # Formats the ingredients nicely.
    def grocery_list(self):
        let shopping_list = [None; self.ingredients.len()]
        for i, ingredient in self.ingredients:
            let pretty = '%s %s of %s'.format(ingredient.quantity,
                                              ingredient.unit,
                                              ingredient.name)
            shopping_list[i] = pretty
        return shopping_list

    # Gets called when the recipe object is printed.
    def __print__(self, print):
        print('%s\n\n', self.name)
        for ingredient in self.grocery_list():
            print('%s\n', ingredient)
        print('\n')
        for step in self.steps:
            print('%s\n', step)
        print('\n')

test 'lentils':
    # Filling, basically-zero prep time, but takes a while to cook.
    let ingredients = [ingredient('Green lentils', 0.33, 'cup'),
                       ingredient('Brown rice', 0.33, 'cup'),
                       ingredient('Water', 2, 'cup'),
                       ingredient('Diced tomatoes', 14, 'oz'),
                       ingredient('Salt', 1, 'tsp'),
                       ingredient('Seasoning', 1, 'tsp')]
    let lentils = Recipe('Lentils and Brown Rice', ingredients)
    lentils.add_step('Put ingredients in rice cooker.')
    lentils.add_step('Cook until done, about 1 hour.')
    assert lentils.grocery_list() == ['0.33 cup of Green lentils',
                                      '0.33 cup of Brown rice',
                                      '2 cup of Water',
                                      '14 oz of Diced tomatoes',
                                      '1 tsp of Salt',
                                      '1 tsp of Seasoning',]
    print('%s', lentils)
