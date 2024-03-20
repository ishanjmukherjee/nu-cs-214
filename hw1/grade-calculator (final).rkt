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
    # error checking: worksheet percentages between 0 and 1 (inclusive)
    for worksheet_percentage in worksheet_percentages:
        if worksheet_percentage > 1 or worksheet_percentage < 0:
            error('worksheet_modifier: percentage must be between 0 and 1 (inclusive)')
    
    if worksheet_percentages[0] == 1 and worksheet_percentages[1] == 1:
        return 1
    if worksheet_percentages[0] >= 0.8 and worksheet_percentages[1] >= 0.8:
        return 0
    return -1
    #   ^ YOUR WORK GOES HERE
    
test 'worksheets modifier function':
    assert_error worksheets_modifier([1.01, 1])
    assert_error worksheets_modifier([0.81, -0.01])
    assert worksheets_modifier([1,1]) == 1
    assert worksheets_modifier([0.8,0.8]) == 0
    assert worksheets_modifier([1,0.8]) == 0
    assert worksheets_modifier([1,0.81]) == 0
    assert worksheets_modifier([1,0.79]) == -1
    assert worksheets_modifier([0.8,0.79]) == -1
    assert worksheets_modifier([0,0]) == -1

def exams_modifiers (exam1: nat?, exam2: nat?) -> int?:
    let modifiers = [0, 0]
    let exams = [exam1, exam2]
    for i in range(exams.len()):
        if exams[i] > 20 or exams[i] < 0: # out of bounds error checking
            error("exams_modifier: exam scores must be between 0 and 20 (inclusive)")
        if exams[i] >= 17:
            modifiers[i] = modifiers[i] + 1
        elif exams[i] >= 11:
            continue
        elif exams[i] >= 8:
            modifiers[i] = modifiers[i] - 1
        elif exams[i] >= 4:
            modifiers[i] = modifiers[i] - 2
        else:
            modifiers[i] = modifiers[i] - 3
        # print debugging statemt:
        # println('%p',modifiers[i])
    let total_exams_modifier = 0
    for modifier in modifiers:
        total_exams_modifier = total_exams_modifier + modifier
    if modifiers[1] >= modifiers[0] + 2:
        total_exams_modifier = total_exams_modifier + 1
    return total_exams_modifier
    
        
    #   ^ YOUR WORK GOES HERE

test 'exams modifiers function':
    # first submission failed tests
    assert exams_modifiers(16, 20) == 1 # modifiers 0 and 1
    assert exams_modifiers(4, 8) == -3 # modifiers -2 and -1
    assert exams_modifiers(13, 15) == 0 # modifiers 0 and 0
    
    # my own tests
    assert exams_modifiers(0, 0) == -6 # both modifiers -3
    assert exams_modifiers(12, 12) == 0 # both modifiers 0
    assert exams_modifiers(11, 16) == 0 # both modifiers 0
    assert exams_modifiers(16, 8) == -1 # modifiers 0 and -1
    assert exams_modifiers(20, 20) == 2 # both modifiers +1
    assert exams_modifiers(4, 19) == 0 # modifiers -2 and +1, with improvement modifier +1
    assert exams_modifiers(17, 10) == 0 # modifiers +1 and -1, with improvement modifier +1
    
    # out of bounds error testing
    assert_error exams_modifiers(21,0)
    assert_error exams_modifiers(19, -1)

def self_evals_modifier (hws: VecC[homework?]) -> int?:
    if hws.len() != 5:
        error('self_evals_modifier: must receive exactly 5 homeworks')
    let num_5s = 0
    let num_3_or_overs = 0
    let num_2_or_belows = 0
    for hw in hws:
        let se_score = hw.self_eval_score
        # out of bounds error checking
        if se_score > 5 or se_score < 0:
            error("self_evals_modifier: self eval score must be between 0 and 5 (inclusive)")
        if se_score == 5:
            num_5s = num_5s + 1
            num_3_or_overs = num_3_or_overs + 1
        elif se_score >= 3:
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
    # number of homeworks must be exactly 5
    assert_error self_evals_modifier([homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}, homework {outcome: 'got it', self_eval_score: 5}])
    assert_error self_evals_modifier([homework {outcome: 'got it', self_eval_score: 5}])
    assert_error self_evals_modifier()
    assert_error self_evals_modifier([homework {outcome: 'got it', self_eval_score: 5}], [homework {outcome: 'got it', self_eval_score: 5}], [homework {outcome: 'got it', self_eval_score: 5}], [homework {outcome: 'got it', self_eval_score: 5}])
    
    struct se_tc: # within-bounds self eval test case
        # notes the modifier applicable to each array of five scores
        let scores: VecC[int?]
        let mod: int?
         
    let valid_test_cases = [se_tc {scores: [5, 5, 5, 5, 5], mod: 1}, se_tc {scores: [5, 5, 5, 5, 0], mod: 1}, se_tc {scores: [3, 3, 5, 0, 0], mod: 0}, se_tc {scores: [0, 0, 0, 5, 5], mod: -1}]
    let out_of_bounds_test_cases = [[6, 1, 2, 3, 4], [-1, 0 , 1, 2, 3]]
    
    for test_case in valid_test_cases:
        assert self_evals_modifier([homework {outcome: 'got it', self_eval_score: test_case.scores[0]}, homework {outcome: 'got it', self_eval_score: test_case.scores[1]}, homework {outcome: 'got it', self_eval_score: test_case.scores[2]}, homework {outcome: 'got it', self_eval_score: test_case.scores[3]}, homework {outcome: 'got it', self_eval_score: test_case.scores[4]}]) == test_case.mod
    
    for test_case in out_of_bounds_test_cases:
        assert_error self_evals_modifier([homework {outcome: 'got it', self_eval_score: test_case[0]}, homework {outcome: 'got it', self_eval_score: test_case[1]}, homework {outcome: 'got it', self_eval_score: test_case[2]}, homework {outcome: 'got it', self_eval_score: test_case[3]}, homework {outcome: 'got it', self_eval_score: test_case[4]}])
    

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
    let grade = 0
    for i in range(letter_grades.len()):
        if letter_grades[i] == base_grade:
            grade = i
            break
    if grade > 0:
        grade = grade + total_modifiers
    if grade > 9:
        grade = 9
    elif grade < 0:
        grade = 0
    return letter_grades[grade]
            
    #   ^ YOUR WORK GOES HERE

test 'apply modifiers fuction':
    assert apply_modifiers('F', +1) == 'F'
    assert apply_modifiers('F', +3) == 'F'
    assert apply_modifiers('A-', +1) == 'A'
    assert apply_modifiers('C', +6) == 'A'
    assert apply_modifiers('C', +7) == 'A'
    assert apply_modifiers('A-', +2) == 'A'
    assert apply_modifiers('B', 1) == 'B+'
    assert apply_modifiers('D', 4) == 'B-' 

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
        self.homeworks[n-1].outcome = new_outcome
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
    
test 'Student#letter_grade, example 1 from syllabus':
    let s = Student('Hermione', [homework('got it',5), homework('got it', 5), homework('got it', 5), homework('almost there', 2), homework('on the way', 2)], project('almost there', 1), [1.0, 1.0], [1, 1, 1, 0, 0], [8, 15])
    
    assert s.base_grade() == 'B'
    assert s.total_modifiers() == 1
    assert s.letter_grade() == 'B+'
    
test 'Student#letter_grade, example 2 from syllabus':
    let s = Student("Ron",
                    [homework("got it", 3),
                     homework("got it", 3),
                     homework("on the way", 3),
                     homework("on the way", 2),
                     homework("not yet", 2)],
                    project("almost there", 1),
                    [1.0, 1.0],
                    [1, 1, 1, 0, 0],
                    [10, 17])
    
    assert s.base_grade() == 'D'
    assert s.project_above_expectations_modifier() == 1
    assert s.total_modifiers() == 4
    assert s.letter_grade() == 'B-'