#lang dssl2

# HW1: Grade Calculator

let eight_principles = ["Know your rights.",
"Acknowledge your sources.",
"Protect your work.",
"Avoid suspicion.",
"Do your own work.",
"Never falsify a record or permit another person to do so.",
"Never fabricate data, citations, or experimental results.",
"Always tell the truth when discussing your work with your instructor."]


###
### Data Definitions
###

let outcome? = OrC("got it", "almost there", "on the way", "not yet",
                   "missing honor code", "cannot assess")

struct homework:
    let outcome: outcome?
    let self_eval_score: nat?

struct project:
    let outcome: outcome?
    let docs_modifier: int?

let letter_grades = ["F", "D", "C-", "C", "C+", "B-", "B", "B+", "A-", "A"]
def letter_grade? (str):
    let found? = False
    for g in letter_grades:
        if g == str: found? = True
    return found?


###
### Modifiers
###

def worksheets_modifier (worksheet_percentages: TupC[num?, num?]) -> int?:
    if worksheet_percentages[0] == 1 and worksheet_percentages[1] == 1:
        return 1
    if worksheet_percentages[0] >= 0.8 and worksheet_percentages[1] >= 0.8:
        return 0
    return -1
    #   ^ YOUR WORK GOES HERE
    
test 'worksheets modifier function':
    assert worksheets_modifier([1,1]) == 1
    assert worksheets_modifier([0.8,0.8]) == 0
    assert worksheets_modifier([1,0.8]) == 0
    assert worksheets_modifier([0.8,0.79]) == -1
    assert worksheets_modifier([0,0]) == -1

def exams_modifiers (exam1: nat?, exam2: nat?) -> int?:
    # out of bounds error checking
    if exam1 > 20 or exam1 < 0 or exam2 > 20 or exam2 < 0:
        error("exam scores out of range")
    let modifier = 0
    for exam in [exam1, exam2]:
        if exam >= 17:
            modifier = modifier + 1
        elif exam >= 11:
            pass
        elif exam >= 8:
            modifier = modifier - 1
        elif exam >= 4:
            modifier = modifier - 2
        else:
            modifier = modifier - 3
    if exam2 >= exam1 + 2:
        modifier = modifier + 1
    return modifier
    
        
    #   ^ YOUR WORK GOES HERE

test 'exams modifiers function':
    assert exams_modifiers(0, 0) == -6
    assert exams_modifiers(20, 20) == 2
    assert exams_modifiers(4, 19) == 0
    assert_error exams_modifiers(21,0)
    assert_error exams_modifiers(19, -1)

def self_evals_modifier (hws: VecC[homework?]) -> int?:
    let num_5s = 0
    let num_3_or_overs = 0
    let num_2_or_belows = 0
    for hw in hws:
        if hw.self_eval_score > 5 or hw.self_eval_score < 0:
            error("self eval out of bounds")
        if hw.self_eval_score == 5:
            num_5s = num_5s + 1
            num_3_or_overs = num_3_or_overs + 1
        elif hw.self_eval_score >= 3:
            num_3_or_overs = num_3_or_overs + 1
        else:
            num_2_or_belows = num_2_or_belows + 1
    if num_5s >= 4:
        return 1
    elif num_3_or_overs >= 3:
        return 0
    else:
        return -1
     
    #   ^ YOUR WORK GOES HERE
        
test 'self evals modifier function':
    assert self_evals_modifier([homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}]) == 1
    assert self_evals_modifier([homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 0}]) == 1
    assert self_evals_modifier([homework {outcome: 'got it', self_eval_score: 3}, homework {outcome: 'got it', self_eval_score: 3}, homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 0}, homework {outcome: 'got it', self_eval_score: 0}]) == 0
    assert self_evals_modifier([homework {outcome: 'got it', self_eval_score: 0}, homework {outcome: 'got it', self_eval_score: 0}, homework {outcome: 'got it', self_eval_score: 0}, homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}]) == -1
    assert_error self_evals_modifier([homework {outcome: 'got it', self_eval_score: 6}, homework {outcome: 'got it', self_eval_score: 0}, homework {outcome: 'got it', self_eval_score: 0}, homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}])
    assert_error self_evals_modifier([homework {outcome: 'got it', self_eval_score: -1}, homework {outcome: 'got it', self_eval_score: 0}, homework {outcome: 'got it', self_eval_score: 0}, homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}])
    

def in_class_modifier (scores: VecC[nat?]) -> int?:
    # 'scores' vector represenst the scores received 
    # on all in-class exercises conducted in class, 
    # including 0s due to missed classes. 
    # The length of the vector should be the number of 
    # exercises conducted in class.
    if scores.len() == 0: error('in_class_modifier: received empty vector')
    let total_ones = 0
    for score in scores:
        total_ones = total_ones + score
    # computes percentage and then rounds
    let in_class_percentage = (total_ones/scores.len())*100
    let in_class_percentage_rounded = (in_class_percentage + 0.5).floor()
    if in_class_percentage_rounded >= 90: return 1
    if in_class_percentage_rounded >= 50 and in_class_percentage_rounded < 90: return 0
    return -1

###
### Letter Grade Helpers
###

# Is outcome x enough to count as outcome y?
def is_at_least (x:outcome?, y:outcome?) -> bool?:
    if x == "got it": return True
    if x == "almost there" \
        and (y == "almost there" or y == "on the way" or y == "not yet"):
        return True
    if x == "on the way" and (y == "on the way" or y == "not yet"): return True
    return False

def apply_modifiers (base_grade: letter_grade?, total_modifiers: int?) -> letter_grade?:
    let base_num_grade = 0
    for num_grade in range(letter_grades.len()):
        if letter_grades[num_grade] == base_grade:
            base_num_grade = num_grade
            break
    let modified_grade = base_num_grade + total_modifiers
    if modified_grade > 9:
        modified_grade = 9
    elif modified_grade < 0:
        modified_grade = 0
    return letter_grades[modified_grade]
            
    #   ^ YOUR WORK GOES HERE


###
### Students
###

class Student:
    let name: str?
    let homeworks: TupC[homework?, homework?, homework?, homework?, homework?]
    let project: project?
    let worksheet_percentages: TupC[num?, num?]
    let in_class_scores: VecC[nat?]
    let exam_scores: TupC[nat?, nat?]

    def __init__ (self, name, homeworks, project, worksheet_percentages, in_class_scores, exam_scores):
        self.name = name
        self.homeworks = homeworks
        self.project = project
        self.worksheet_percentages = worksheet_percentages
        self.in_class_scores = in_class_scores
        self.exam_scores = exam_scores 
    #   ^ YOUR WORK GOES HERE

    def get_homework_outcomes(self) -> VecC[outcome?]:
        return [hw.outcome for hw in self.homeworks]
    #   ^ YOUR WORK GOES HERE

    def get_project_outcome(self) -> outcome?:
        return self.project.outcome
    #   ^ YOUR WORK GOES HERE

    def resubmit_homework (self, n: nat?, new_outcome: outcome?) -> NoneC:
        if n < 1 or n > 5:
            error("homework index out of bounds")
        self.homeworks[n].outcome = new_outcome
    #   ^ YOUR WORK GOES HERE

    def resubmit_project (self, new_outcome: outcome?) -> NoneC:
        self.project.outcome = new_outcome
    #   ^ YOUR WORK GOES HERE

    def base_grade (self) -> letter_grade?:
        let n_got_its       = 0
        let n_almost_theres = 0
        let n_on_the_ways   = 0
        for o in self.get_homework_outcomes():
            if is_at_least(o, "got it"):
                n_got_its       = n_got_its       + 1
            if is_at_least(o, "almost there"):
                n_almost_theres = n_almost_theres + 1
            if is_at_least(o, "on the way"):
                n_on_the_ways   = n_on_the_ways   + 1
        let project_outcome = self.get_project_outcome()
        if n_got_its == 5 and project_outcome == "got it": return "A-"
        # the 4 "almost there"s or better include the 3 "got it"s
        if n_got_its >= 3 and n_almost_theres >= 4 and n_on_the_ways >= 5 \
           and is_at_least(project_outcome, "almost there"):
            return "B"
        if n_got_its >= 2 and n_almost_theres >= 3 and n_on_the_ways >= 4 \
           and is_at_least(project_outcome, "on the way"):
            return "C+"
        if n_got_its >= 1 and n_almost_theres >= 2 and n_on_the_ways >= 3 \
           and is_at_least(project_outcome, "on the way"):
            return "D"
        return "F"

    def project_above_expectations_modifier (self) -> int?:
        let base_grade = self.base_grade()
        if base_grade == 'A-': return 0 # expectations are already "got it"
        if base_grade == 'B':
            if is_at_least(self.project.outcome, 'got it'):       return 1
            else: return 0
        else:
            # two steps ahead of expectations
            if is_at_least(self.project.outcome, 'got it'):       return 2
            # one step ahead of expectations
            if is_at_least(self.project.outcome, 'almost there'): return 1
            else: return 0

    def total_modifiers (self) -> int?:
        return exams_modifiers(self.exam_scores[0], self.exam_scores[1]) + worksheets_modifier(self.worksheet_percentages) + self_evals_modifier(self.homeworks) + in_class_modifier(self.in_class_scores) + self.project_above_expectations_modifier() + self.project.docs_modifier
    #   ^ YOUR WORK GOES HERE

    def letter_grade (self) -> letter_grade?:
        return apply_modifiers(self.base_grade(), self.total_modifiers())
    #   ^ YOUR WORK GOES HERE

###
### Feeble attempt at a test suite
###
        
test 'worksheets_modifier, negative modifier':
    assert worksheets_modifier([0.5, 0.85]) == -1
    assert worksheets_modifier([0.3, 0.79]) == -1
    
test 'Student#letter_grade, worst case scenario':
    let s = Student('Everyone, right now',
                    [homework("not yet", 0),
                     homework("not yet", 0),
                     homework("not yet", 0),
                     homework("not yet", 0),
                     homework("not yet", 0)],
                    project("not yet", -1),
                    [0.0, 0.0],
                    [0], # Since vector length can't be 0
                    [0, 0])
    assert s.base_grade() == 'F'
    assert s.total_modifiers() == -10
    assert s.letter_grade() == 'F'

test 'Student#letter_grade, best case scenario':
    let s = Student("You, if you work harder than you've ever worked",
                    [homework("got it", 5),
                     homework("got it", 5),
                     homework("got it", 5),
                     homework("got it", 5),
                     homework("got it", 5)],
                    project("got it", 1),
                    [1.0, 1.0],
                    [1, 1, 1, 1, 1],
                    [20, 20])
    assert s.base_grade() == 'A-'
    assert s.total_modifiers() == 6
    assert s.letter_grade() == 'A'