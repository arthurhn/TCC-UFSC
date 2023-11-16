#Foi feito ele não adicionar individuos repetidos na lista (por isso não ta 100%)
#(15/11/2023)

import time
import random
import numpy as np
import os
import sys
import matplotlib.pyplot as plt
from v1_1_fisics_dumper import *

limit_generation_ = 500
generation_size_ = 200
chart_on = True
if(chart_on):
    plt.ion()
class DynamicUpdate():
    #Suppose we know the x range
    min_x = 0
    max_x = limit_generation_

    def on_launch(self):
        #Set up plot
        self.figure, self.ax = plt.subplots(2)
        # self.figure.suptitle('Área variável')
        self.lines, = self.ax[0].plot([],[], '-')
        self.lines1, = self.ax[1].plot([],[], '-')
        #Autoscale on unknown axis and known lims on the other
        self.ax[0].set_autoscaley_on(True)
        self.ax[0].set_xlim(self.min_x, self.max_x)
        self.ax[1].set_autoscaley_on(True)
        self.ax[1].set_xlim(self.min_x, self.max_x)
        #Other stuff
        self.ax[0].set_ylabel('Precisão do melhor')
        self.ax[1].set_xlabel('Geração')
        self.ax[1].set_ylabel('Select Pressure')
        self.ax[0].grid()
        self.ax[1].grid()

    def on_running(self, xdata, ydata1, ydata2):
        #Update data (with the new _and_ the old points)
        self.lines, = self.ax[0].plot(xdata,ydata1, 'r-')
        self.lines1, = self.ax[1].plot(xdata,ydata2, 'b-')
        # self.lines.set_ydata(new_ydata)
        #Need both of these in order to rescale
        self.ax[0].relim()
        self.ax[1].relim()
        self.ax[1].autoscale_view()
        self.ax[0].autoscale_view()
        #We need to draw *and* flush
        self.figure.canvas.draw()
        self.figure.canvas.flush_events()
        
undone = True

if(chart_on):
    d = DynamicUpdate()
    d.on_launch()
xdata = []
ydata_sp = []
ydata_ac = []

#inicial parameters
error_ = [0.02, 0.02, 0.02, 0.02, 0.02]
discrete_value_mm = 1
rigidez_lenght_min = 2/1000
rigidez_lenght_max = 15/1000
aco_lenght_min = 3/1000
aco_lenght_max = 15/1000

#other parameters

#standards frequency targets
frequency_target = [1872.1, 1470.6, 1036.3, 629.9, 129.9]
# frequency_target = [1774,1524,1452,1025,675]
# frequency_target = [2000, 1500, 1000, 700, 200]
# frequency_target = [6000, 3300, 1100, 400, 200]

#real materials thickness (mm)
rigidez_options_mm = [2, 3, 4]
aco_options_mm = [3, 3.3, 3.8, 5]
comprimento_options = [0.40, 0.41, 0.42, 0.43, 0.44, 0.45, 0.46, 0.47, 0.48, 0.49, 0.50, 0.51, 0.52, 0.53, 0.54, 0.55, 0.55, 0.56, 0.57, 0.58, 0.59, 0.60]
largura_options = [0.045, 0.046, 0.047, 0.048, 0.049, 0.050, 0.051, 0.052, 0.053, 0.054, 0.055]

#getting parameters from executation line
if(len(sys.argv) >= 11):
    error_ = [float(sys.argv[6])/100, float(sys.argv[7])/100, float(sys.argv[8])/100, float(sys.argv[9])/100, float(sys.argv[10])/100]
    discrete_value_mm = float(sys.argv[1])
    rigidez_lenght_min = float(sys.argv[2])/1000
    rigidez_lenght_max = float(sys.argv[3])/1000
    aco_lenght_min = float(sys.argv[4])/1000
    aco_lenght_max = float(sys.argv[5])/1000


#parameters as global variables
av_error = np.sum(error_)/5
accuracy_target = 1/av_error
discrete_value = discrete_value_mm/1000
select_pressure_vector = []


#auxiliar functions
def expovariate(len_ranked_rigidez):
    v = [] 
    size_array = len_ranked_rigidez-1
    for _ in range(size_array): 
        temp = random.expovariate(0.000001)
        v.append(temp) 
    v.sort(reverse=True)
    normalized_v = v/np.linalg.norm(v)
    normalized_v = size_array*normalized_v/normalized_v[0]
    choice = [int(i) for i in normalized_v]
    i = random.choice(choice)#escolhendo uma das melhores amostrar
    return i
def select_thickness(vector_mm):
    times = random.randint(1, 3)
    answer = 0
    original = []
    for _ in range(times):
        choice = random.choice(vector_mm)
        answer = answer + choice/1000
        original.append(choice)
        #remove bug at decimals
        answer = round(answer*100000)
        answer = answer/100000
    return (answer, original)
def print_current_best_individual(best_tuple, rankedsolutions, i):
    os.system('cls' if os.name == 'nt' else 'clear')
    print(f"Best until now:")
    print(f"  Accuracy:          {round(best_tuple[0], 4)}")
    print(f"  Expected(Hz):      {frequency_target}")
    print(f"  Obtained(Hz):      {[int(freq) for freq in best_tuple[4]]}")
    print(f"  Vector error (%):  {[round(er*100, 2) for er in best_tuple[3]]}")
    print(f"  Average error (%): {round(np.sum(best_tuple[3])/5*100, 4)}")
    print(f"  Spring (mm):       {[round(er[2]*1000, 2) for er in best_tuple[1]]}")
    print(f"  Mass (mm):         {[round(er[2]*1000, 2) for er in best_tuple[2]]}")
    print(f"  Lenght (cm):       {round(best_tuple[5]*100, 1)}")
    print(f"  Width (mm):        {round(best_tuple[6]*1000, 1)}")
    print(f"  Elasticity (MPa):  {round(Et/(10e5), 2)}")


    print()
    print(f"=== Gen {i+1} bests solutions ===")
    for j in range(3):
        aux_vector_error = rankedsolutions[j][3]
        aux_error = np.sum(aux_vector_error)/5*100
        total_weight = weight_calculate(rankedsolutions[j][2], rankedsolutions[j][1], 0.50, 0.051)
        # print(f"Error: {round(aux_error, 2)}% and vector_error: {[round(100*er, 2) for er in rankedsolutions[j][3]]}%")
        # print(f"Average Error: {round(aux_error, 2)}% and Weight: {round(total_weight, 2)}kg")
        print(f"Accuracy: {round(rankedsolutions[j][0], 4)},   Weight: {round(total_weight, 2)}kg.")
        # print(f"Error: {[round(er, 2) for er in rankedsolutions[j][3]]}% and Weight: {round(total_weight, 2)}kg")
    print()
    #Select Pressure printing
    best_accurary, average_accurary = select_pressure(rankedsolutions)
    g0 = 1/best_accurary
    g = 1/average_accurary
    current_select_pressure = g0/g 
    select_pressure_vector.append(current_select_pressure)
    print(f"Current Select Pressure: {round(current_select_pressure*100, 2)}%,")
    print(f"Best error: {round(g0*100, 2)}%, Average error: {round(g*100, 2)}%")
    print("Mutation Local")

    #----------- Printing chart ---------------------
    if(chart_on):
        xdata.append(i)
        ydata_sp.append(current_select_pressure)
        ydata_ac.append(rankedsolutions[0][0])
        if(limit_generation_ < 150):
            d.ax[0].set_xlim(0, limit_generation_-1)
            d.ax[1].set_xlim(0, limit_generation_-1)
        if(i%150 == 0):
            if(i==150):
                plt.savefig('parcial_sp_2_2_1.pdf', dpi=300)
            d.ax[0].set_xlim(i, i+150)
            d.ax[1].set_xlim(i, i+150)
        if(i==limit_generation_-1):
            d.ax[0].set_xlim(0, limit_generation_-1)
            d.ax[1].set_xlim(0, limit_generation_-1)
        d.on_running(xdata, ydata_ac, ydata_sp)
def print_best_individual(start, end, correct_ans, best_tuple):
    os.system('cls' if os.name == 'nt' else 'clear')
    print()
    print("====== Best results ======")
    print()

    print(f"Expected frequencys(Hz): {correct_ans}")
    ans_frequency = main_function(best_tuple[2], best_tuple[1])
    print("Obtained frequencys(Hz): [", end="")

    for d in range(len(ans_frequency)):
        if d != (len(ans_frequency)-1):
            print(f"{int(ans_frequency[d])}, ", end="")
        else:
            print(f"{int(ans_frequency[d])}]", end="")
    print()
    average_error = 0
    for i in range(len(correct_ans)):
        average_error += abs((ans_frequency[i]-correct_ans[i])/correct_ans[i])
    average_error = average_error/len(correct_ans)
    print(f"Error per frequency:     {[round(err*100, 2) for err in best_tuple[3]] }%")
    print(f"Average error:           {round(average_error*100, 4)}%")
    print(f"Accuracy:                {round(best_tuple[0], 4)}")
    print()

    total_weight = weight_calculate(best_tuple[2], best_tuple[1], 0.50, 0.051)
    print(f"Weight: {round(total_weight, 2)}kg")

    rigidez_mm = []
    aco_mm = []
    for s in best_tuple[1]:
        rigidez_mm.append(s[2]*1000)
    for s in best_tuple[2]:
        aco_mm.append(s[2]*1000)
    print(f"Spring thickness(mm):    {[round(r, 2) for r in rigidez_mm]}")#thickness = espessura
    print(f"Mass thickness(mm):      {[round(r, 2) for r in aco_mm]}")
    print(f"Lenght (cm):             {round(best_tuple[5]*100, 1)}")
    print(f"Width (mm):              {round(best_tuple[6]*1000, 1)}")
    print(f"Accuracy:                {round(best_tuple[0], 4)}")
    print(f"Elasticity (MPa):  {round(Et/(10e5), 2)}")
    print("Mutation Local")
    print()
    print(f"Finished in {round(end-start, 2)}s / {round((end-start)/60)}min / {round((end-start)/60/60, 2)}h")
    return



#rate a individual
def fitness(aco, rigidez, comprimento, largura, correct_ans):
    error = 0
    # print(f"peso: {total_weight}kg")
    # sys.exit()
    
    #Limitation of weight values part
    total_weight = weight_calculate(aco, rigidez, 0.50, 0.051)
    if(total_weight < 4 or total_weight > 9):
        error = 10**10

    #Limitation of thickness values part  
    for _aco in aco:
        if(_aco[2] < aco_lenght_min or _aco[2] > aco_lenght_max):
            error = 10**10
    for _rigidez in rigidez:
        if(_rigidez[2] < rigidez_lenght_min or _rigidez[2] > rigidez_lenght_max):
            error = 10**10
    if(comprimento <= 0.4 or comprimento >= 0.6):
            error = 10**10
    if(largura <= 0.045 or largura >= 0.055):
            error = 10**10

    if(error != 0):
        return [0, [1, 1, 1, 1, 1], [0, 0, 0, 0, 0]]
    
    ans = main_function(aco, rigidez)
    ans = np.sort(ans)
    ans = ans[::-1]
    vector_error = [((ans[0]-correct_ans[0])/correct_ans[0]), ((ans[1]-correct_ans[1])/correct_ans[1]), ((ans[2]-correct_ans[2])/correct_ans[2]), ((ans[3]-correct_ans[3])/correct_ans[3]), ((ans[4]-correct_ans[4])/correct_ans[4])]
    vector_error = [abs(v) for v in vector_error]
    weight = [2, 3, 4, 5, 1]
    error = (vector_error[0]*weight[0] + vector_error[1]*weight[1] + vector_error[2]*weight[2] + vector_error[3]*weight[3] + vector_error[4]*weight[4])/np.sum(weight)
    if error == 0:
        return 9999999999
    return [abs(1/error), vector_error, ans]

#creates the first generation
def generate_new_solution(generation_size):
    _aco = []
    _rigidez = []
    _comprimento = []
    _largura = []
    for _ in range(generation_size):
        # list_rigidez = [select_thickness(rigidez_options_mm) for _ in range(5)]
        list_rigidez = [select_thickness(rigidez_options_mm)[0] for _ in range(5)]
        # list_aco = [select_thickness(aco_options_mm) for _ in range(5)]
        list_aco = [select_thickness(aco_options_mm)[0] for _ in range(5)]
    
        _rigidez.append(list_rigidez)
        _aco.append(list_aco)
        _comprimento.append(round(random.choice(comprimento_options), 6))
        _largura.append(round(random.choice(largura_options), 6))
        
    return _rigidez, _aco, _comprimento, _largura

#for now, the loop function
def selection_function(p_rigidez, p_aco, p_comprimento, p_largura, correct_ans, limit_generations, generation_size):
    assert len(p_rigidez) == len(p_aco) and len(p_comprimento) == len(p_largura) and len(p_comprimento) == len(p_rigidez), "Vetor de rigidezes, acos, comprimento e/ou largura com tamanhos diferentes"

    #assigned the first tuple for compare 
    rigidez, aco = parametros(p_rigidez[0], p_aco[0], 0.50, 0.051)
    parcial_vector = fitness(aco, rigidez, p_comprimento[0], p_largura[0], correct_ans)
    precision = parcial_vector[0]
    vector_errors = parcial_vector[1]
    vector_ans = parcial_vector[2]
    best_tuple = (precision, rigidez, aco, vector_errors, vector_ans, p_comprimento[0], p_largura[0])

    unfinished = True
    start = time.time()
    for i in range(limit_generations):
        rankedsolutions = []
        #creates individuals (tuples) from the measures (p_rigidez, p_aco)
        for j in range(len(p_rigidez)):
            rigidez, aco = parametros(p_rigidez[j], p_aco[j], 0.50, 0.051)
            parcial_vector = fitness(aco, rigidez, p_comprimento[j], p_largura[j], correct_ans)
            precision = parcial_vector[0]
            vector_errors = parcial_vector[1]
            vector_ans = parcial_vector[2]
            if(precision != 0 or len(rankedsolutions) < 10): # menor then 10 because we chose between the 10 best, so its a guarantee that rankedsolution will have 10 size
                rankedsolutions.append((precision, rigidez, aco, vector_errors, vector_ans, p_comprimento[j], p_largura[j])) #tuple contains the value of result (acuracy) and rididez and aco vector
        
        #sort the individuals, from the best to worst
        rankedsolutions_sort = [rankedsolutions[0]]
        for k in range(0, len(rankedsolutions)):
            for j in range(len(rankedsolutions_sort)):
                if(rankedsolutions[k][0] > rankedsolutions_sort[j][0]):
                    rankedsolutions_sort.insert(j, rankedsolutions[k])
                    break
                if (rankedsolutions[k][0] <= rankedsolutions_sort[j][0] and j == len(rankedsolutions_sort)-1):
                    rankedsolutions_sort.append(rankedsolutions[k])
                    break
        rankedsolutions = rankedsolutions_sort
        rankedsolutions.pop()
        


        #update the current best indivial
        if(best_tuple[0] < rankedsolutions[0][0]):
            best_tuple = rankedsolutions[0]

        #print the best individual info
        print_current_best_individual(best_tuple, rankedsolutions, i)

        #stop code if it find the optimal individual based on requirements
        best_error = rankedsolutions[0][3]
        if  (best_error[0] < error_[0] and best_error[1] < error_[1] and best_error[2] < error_[2] and best_error[3] < error_[3] and best_error[4] < error_[4]):
            best_tuple = rankedsolutions[0]
            unfinished = False
            break

        crossover_generation = crossover_function(rankedsolutions[:10])
        p_rigidez, p_aco, p_comprimento, p_largura = mutation_function(crossover_generation, generation_size)
        # time.sleep(1.5)

    #print the final solution at end of the limit generation
    end = time.time()
    print_best_individual(start, end, correct_ans, best_tuple)
    if(unfinished == False):
        return False
    return True

#mix thickness between individuals
def crossover_function(bestsolutions):
    element_rigidez = []#array of thickness
    element_aco = []#array of thickness
    element_lenght = []#array of lenghts
    element_width = []#array of widths
    #create both arrays from tuple to vectors
    for s in bestsolutions:
        _rigidez = []
        _aco = []
        element_lenght.append(s[5])
        element_width.append(s[6])
        for i in range(len(s[1])):
            _rigidez.append(s[1][i][2])
            _aco.append(s[2][i][2])
        element_rigidez.append(_rigidez)
        element_aco.append(_aco)
    original_rigidez_thickness = np.copy(element_rigidez)
    original_aco_thickness = np.copy(element_aco)
    original_lenght = np.copy(element_lenght)
    original_width = np.copy(element_width)

    crossover_rigidez = []
    crossover_aco = []
    iteractions = 0
    while(len(crossover_rigidez) != 10):
        who_is_change = random.randint(0, 2) #0 -> just rigidez will change, 1 -> just aco, 2 -> both
        how_many_try_changes = random.randint(1, 4)
        chosen_position = random.randint(0, 10-1)
        # print(f"original: {chosen_position}, who_is_change: {who_is_change}, how_many_try_changes: {how_many_try_changes}")
        chosen_position2 = random.randint(0, 10-1)
        while (chosen_position2 == chosen_position):
            chosen_position2 = random.randint(0, 10-1)

        new_rigidez = np.copy(original_rigidez_thickness[chosen_position])
        new_aco = np.copy(original_aco_thickness[chosen_position])
        
        new_rigidez_copy = np.copy(original_rigidez_thickness[chosen_position2])
        new_aco_copy = np.copy(original_aco_thickness[chosen_position2])
        if(who_is_change == 0):
            for _ in range(how_many_try_changes):
                change_position = random.randint(0, 4)
                new_rigidez[change_position] = new_rigidez_copy[change_position]
        if(who_is_change == 1):
            for _ in range(how_many_try_changes):
                change_position = random.randint(0, 4)
                new_aco[change_position] = new_aco_copy[change_position]
        if(who_is_change == 2):
            for _ in range(how_many_try_changes):
                change_position = random.randint(0, 4)
                new_rigidez[change_position] = new_rigidez_copy[change_position]
            how_many_try_changes = random.randint(1, 4)
            for _ in range(how_many_try_changes):
                change_position = random.randint(0, 4)
                new_aco[change_position] = new_aco_copy[change_position]
        
        
        
        # if(iteractions == 15):
            # print(f"original_rigidez_thickness: {original_rigidez_thickness}", end='')
            # print(f"original_aco_thickness: {original_aco_thickness}")

        #--------------verificando se ja não existe na list original ou na propria lista que esta sendo formada-------
        #transformando pra np.array pra poder comparar vetores
        new_rigidez = np.array(new_rigidez)
        new_aco = np.array(new_aco)
        original_rigidez_thickness = np.array(original_rigidez_thickness)
        original_aco_thickness = np.array(original_aco_thickness)
        
        crossover_rigidez_copy = np.array(crossover_rigidez)
        crossover_aco_copy = np.array(crossover_aco)
        
        exist = False
        #verificando se ja existe nos 10 melhores
        for j in range(len(original_rigidez_thickness)):
            if(np.array_equal(new_rigidez, original_rigidez_thickness[j]) and np.array_equal(new_aco, original_aco_thickness[j])):
                # print(f"escolhidos: {chosen_position} e {chosen_position2}, j: {j}")
                # print(f"{new_rigidez} == {original_rigidez_thickness[j]}")
                # print(f"{new_aco} == {original_aco_thickness[j]}")
                exist = True 
        #verificando se ja existe no proprio crossover
        for j in range(len(crossover_rigidez_copy)):
            if(np.array_equal(new_rigidez, crossover_rigidez_copy[j]) and np.array_equal(new_aco, crossover_aco_copy[j])):
                exist = True 

        if(exist == False or iteractions >= 1000):
            crossover_rigidez.append(new_rigidez)
            crossover_aco.append(new_aco)
        # print("preso cros ", end='')
        iteractions += 1
                
    return original_rigidez_thickness, original_aco_thickness, original_lenght, original_width, crossover_rigidez, crossover_aco

#add a small rand value or select another possible thickness
def mutation_function(elements, generation_size):
    ranked_rigidez, ranked_aco, ranked_lenght, ranked_width, crossover_rigidez, crossover_aco = elements
    new_rigidez = []
    new_aco = []
    new_lenght = []
    new_width = []
    assert len(ranked_rigidez) == len(ranked_aco), "Vetor p_ridizes e p_aco com tamanhos diferentes, mutation_function"
    assert len(crossover_rigidez) == len(crossover_aco), "Vetor crossover_rigidez e crossover_aco com tamanhos diferentes, mutation_function"
    
    #concatenate both arrays
    solutions_rigidez = []
    for i in range(len(ranked_rigidez)+len(crossover_rigidez)):
        if i < len(ranked_rigidez):
            solutions_rigidez.append(ranked_rigidez[i])
        else:
            solutions_rigidez.append(crossover_rigidez[i-len(ranked_rigidez)])
    solutions_aco = []
    for i in range(len(ranked_aco)+len(crossover_aco)):
        if i < len(ranked_aco):
            solutions_aco.append(ranked_aco[i])
        else:
            solutions_aco.append(crossover_aco[i-len(ranked_aco)])
   
   
    iteractions =0
    # for _ in range(generation_size-10):
    while(len(new_rigidez) != generation_size-10):
        one_rigidez = []
        one_aco = []
        #dado o vector concatenado solutions, o valor de i que é quem vai escolher o individuo a ser mutado para criar um novo, 
        # será em média, 50% das vezes a primeira metade do vector (ranked_rigidez) que é quem tem as melhores soluções 
        # da generação antiga, tendendo a escolher o melhor através da expovariete e 50% totalmente randomico dos que receberem crossover (cruzamento)
        best_or_crossver = random.randint(0, 1)
        if(best_or_crossver == 1):
            i = expovariate(len(ranked_rigidez))#escolhendo uma das melhores amostrar (metodo antigo)
        else:
            i = random.randint(0, len(crossover_rigidez)-1)+len(ranked_rigidez)
        #------------------------------------------------------------------------------------------
        signal = [-1, 1]

        
        how_is_change = random.randint(0, 3) #0 -> only rigidez will change, 1 -> only aco, 2 -> both, 3 -> none 

        if(how_is_change == 0):
            #rigidez changed
            for j in range(len(solutions_rigidez[0])):
                new_lenght_rigidez = select_thickness(rigidez_options_mm)[0]
                # new_lenght_rigidez = abs(solutions_rigidez[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
                while new_lenght_rigidez < 0.000001:
                    new_lenght_rigidez = select_thickness(rigidez_options_mm)[0]
                    # new_lenght_rigidez = abs(solutions_rigidez[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
                one_rigidez.append(round(new_lenght_rigidez, 6)) #current number +- 0.001 or 0.002 ....
            #aco doesnt change
            one_aco = [solutions_aco[i][j] for j in range(len(solutions_aco[i]))]

        elif(how_is_change == 1):
            #rigidez doesnt change
            one_rigidez = [solutions_rigidez[i][j] for j in range(len(solutions_rigidez[i]))]
            #aco changed
            for j in range(len(solutions_aco[0])):
                new_lenght_aco = select_thickness(aco_options_mm)[0]
                # new_lenght_aco = abs(solutions_aco[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
                while new_lenght_aco < 0.000001:
                    new_lenght_aco = select_thickness(aco_options_mm)[0]
                    # new_lenght_aco = abs(solutions_aco[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
                one_aco.append(round(new_lenght_aco, 6)) #current number +- 0.001 or 0.002 ....

        elif(how_is_change == 2):
            #both changed
            for j in range(len(solutions_aco[0])):
                new_lenght_aco = select_thickness(aco_options_mm)[0]
                # new_lenght_aco = abs(solutions_aco[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
                while new_lenght_aco < 0.000001:
                    new_lenght_aco = select_thickness(aco_options_mm)[0]
                    # new_lenght_aco = abs(solutions_aco[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
                one_aco.append(round(new_lenght_aco, 6)) #current number +- 0.001 or 0.002 ....
            for j in range(len(solutions_rigidez[0])):
                new_lenght_rigidez = select_thickness(rigidez_options_mm)[0]
                # new_lenght_rigidez = abs(solutions_rigidez[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
                while new_lenght_rigidez < 0.000001:
                    new_lenght_rigidez = select_thickness(rigidez_options_mm)[0]
                    # new_lenght_rigidez = abs(solutions_rigidez[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
                one_rigidez.append(round(new_lenght_rigidez, 6)) #current number +- 0.001 or 0.002 ....

        elif(how_is_change == 3):
            #both doesnt change
            one_rigidez = [solutions_rigidez[i][j] for j in range(len(solutions_rigidez[i]))]
            one_aco = [solutions_aco[i][j] for j in range(len(solutions_aco[i]))]
      
        mutation_on_lenght_or_width = [0, 1, 2]
        choice2 = random.choice(mutation_on_lenght_or_width)
        if(choice2 == 0):
            new_lenght.append(random.choice(comprimento_options))
            new_width.append(random.choice(ranked_width))
        elif(choice2 == 1):
            new_width.append(random.choice(largura_options))
            new_lenght.append(random.choice(ranked_lenght))
        else:
            new_width.append(random.choice(largura_options))
            new_lenght.append(random.choice(comprimento_options))

        new_rigidez.append(one_rigidez)
        new_aco.append(one_aco)

    #-------------verificando se já existe----------

        #transformando pra np.array pra poder comparar vetores
        new_rigidez_copy = np.array(new_rigidez)
        new_aco_copy = np.array(new_aco)

        one_rigidez = np.array(one_rigidez)
        one_aco = np.array(one_aco)
        
        ranked_rigidez_copy = np.array(ranked_rigidez)
        ranked_aco_copy = np.array(ranked_aco)

        exist = False
        #verificando se ja existe no proprio crossover
        for j in range(len(new_rigidez_copy)):
            if(np.array_equal(new_rigidez_copy[j], one_rigidez) and np.array_equal(new_aco_copy[j], one_aco)):
                exist = True 
        #verificando se ja existe nos 10 melhores
        for j in range(len(ranked_rigidez_copy)):
            if(np.array_equal(ranked_rigidez_copy[j], one_rigidez) and np.array_equal(ranked_aco_copy[j], one_aco)):
                exist = True 

        if(exist == False or iteractions >= 1000):
            new_rigidez.append(one_rigidez)
            new_aco.append(one_aco)
        # print("preso mut ", end='')
        # iteractions += 1

    #adding the 10 best again 
    for ri in ranked_rigidez:
        new_rigidez.append(ri)
    for ac in ranked_aco:
        new_aco.append(ac)
    for le in ranked_lenght:
        new_lenght.append(le)
    for wi in ranked_width:
        new_width.append(wi)

    # Criando uma lista de índices únicos
    indices_unicos = []
    for i, (rigidez, aco) in enumerate(zip(new_rigidez, new_aco)):
        if i not in indices_unicos:
            # Procurando por vetores duplicados
            duplicado = False
            for j in range(i + 1, len(new_rigidez)):
                if np.array_equal(rigidez, new_rigidez[j]) and np.array_equal(aco, new_aco[j]):
                    duplicado = True
                    break
            if not duplicado:
                indices_unicos.append(i)

    # Selecionando apenas os itens únicos
    new_rigidez_unicos = [new_rigidez[i] for i in indices_unicos]
    new_aco_unicos = [new_aco[i] for i in indices_unicos]
    new_lenght_unicos = [new_lenght[i] for i in indices_unicos]
    new_width_unicos = [new_width[i] for i in indices_unicos]

    
    return new_rigidez_unicos, new_aco_unicos, new_lenght_unicos, new_width_unicos

#old mutation function, not considering any crossover if use this one
def global_mutation_function(elements, generation_size):
    ranked_rigidez, ranked_aco, ranked_lenght, ranked_width, crossover_rigidez, crossover_aco = elements
    new_rigidez = []
    new_aco = []
    new_lenght = []
    new_width = []
    assert len(ranked_rigidez) == len(ranked_aco), "Vetor p_ridizes e p_aco com tamanhos diferentes, mutation_function"
    assert len(crossover_rigidez) == len(crossover_aco), "Vetor crossover_rigidez e crossover_aco com tamanhos diferentes, mutation_function"
    
    #concatenate both arrays
    solutions_rigidez = []
    for i in range(len(ranked_rigidez)+len(crossover_rigidez)):
        if i < len(ranked_rigidez):
            solutions_rigidez.append(ranked_rigidez[i])
        else:
            solutions_rigidez.append(crossover_rigidez[i-len(ranked_rigidez)])
    solutions_aco = []
    for i in range(len(ranked_aco)+len(crossover_aco)):
        if i < len(ranked_aco):
            solutions_aco.append(ranked_aco[i])
        else:
            solutions_aco.append(crossover_aco[i-len(ranked_aco)])
   
   
    for _ in range(generation_size-10):
        one_rigidez = []
        one_aco = []
        #dado o vector concatenado solutions, o valor de i que é quem vai escolher o individuo a ser mutado para criar um novo, 
        # será em média, 50% das vezes a primeira metade do vector (ranked_rigidez) que é quem tem as melhores soluções 
        # da generação antiga, tendendo a escolher o melhor através da expovariete e 50% totalmente randomico dos que receberem crossover (cruzamento)
        best_or_crossver = random.randint(0, 1)
        if(best_or_crossver == 1):
            i = expovariate(len(ranked_rigidez))#escolhendo uma das melhores amostrar (metodo antigo)
        else:
            i = random.randint(0, len(crossover_rigidez)-1)+len(ranked_rigidez)
        #------------------------------------------------------------------------------------------
        signal = [-1, 1]
        
        for j in range(len(solutions_aco[0])):
            new_lenght_aco = select_thickness(aco_options_mm)[0]
            # new_lenght_aco = abs(solutions_aco[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
            while new_lenght_aco < 0.000001:
                new_lenght_aco = select_thickness(aco_options_mm)[0]
                # new_lenght_aco = abs(solutions_aco[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
            one_aco.append(round(new_lenght_aco, 6)) #current number +- 0.001 or 0.002 ....
        
        for j in range(len(solutions_rigidez[0])):
            # new_lenght_rigidez = select_thickness(rigidez_options_mm)[0]
            new_lenght_rigidez = abs(solutions_rigidez[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
            while new_lenght_rigidez < 0.000001:
                # new_lenght_rigidez = select_thickness(rigidez_options_mm)[0]
                new_lenght_rigidez = abs(solutions_rigidez[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
            one_rigidez.append(round(new_lenght_rigidez, 6)) #current number +- 0.001 or 0.002 ....
        
        mutation_on_lenght_or_width = [0, 1, 2]
        choice2 = random.choice(mutation_on_lenght_or_width)
        if(choice2 == 0):
            new_lenght.append(random.choice(comprimento_options))
            new_width.append(random.choice(ranked_width))
        elif(choice2 == 1):
            new_width.append(random.choice(largura_options))
            new_lenght.append(random.choice(ranked_lenght))
        else:
            new_width.append(random.choice(largura_options))
            new_lenght.append(random.choice(comprimento_options))

        new_rigidez.append(one_rigidez)
        new_aco.append(one_aco)
    for ri in ranked_rigidez:
        new_rigidez.append(ri)
    for ac in ranked_aco:
        new_aco.append(ac)
    for le in ranked_lenght:
        new_lenght.append(le)
    for wi in ranked_width:
        new_width.append(wi)
    return new_rigidez, new_aco, new_lenght, new_width



def select_pressure(generation_tuples):
    vector_error = []

    best_individual_error = generation_tuples[0][0]
    for individual in generation_tuples:
        if(individual[0] != 0):
            vector_error.append(individual[0])
    average_error = np.sum(vector_error)/(len(vector_error))
    return best_individual_error, average_error

#--------------------------teste select_function-------------------------------------
print("--------------------------Start Code-------------------------------------")
rigidez, aco, comprimento, largura = generate_new_solution(generation_size_)
#parameters                     [L,C,tmola,Eepdm],  [L,C,taco], [comprimento],  [largura,  [Hz, Hz, Hz, Hz, Hz],   limit_generation,   generation_size
undone = selection_function  (  rigidez,            aco,        comprimento,    largura,   frequency_target,       limit_generation_,  generation_size_)

if chart_on:
    plt.savefig('final_sp_2_2_2.pdf', dpi=300)


# if(undone):
#     print("Preparing to rerun")
#     time.sleep(1)
#     for _ in range(5):
#         print(".")
#         time.sleep(0.6)
#     os.execv(sys.executable, ['python3'] + sys.argv)

print("xdata: ")
print(xdata)
print("ydata_sp: ")
print([round(valor, 4) for valor in ydata_sp])
print("ydata_ac: ")
print([round(valor, 2) for valor in ydata_ac])

print("--------------------End v2.2.2--------------------")