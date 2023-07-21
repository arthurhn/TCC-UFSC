#Melhoras em termos organizacionais e estruturais do código, como por exemplo a criação
#de uma biblioteca que resolve o problema físico chamada de v1_0_fisics_dumper, onde essa trabalha 
#com comprimento e largura fixas. Porém ainda foi implementada a função select_thickness, que melhora
#a função do código anterior, pegando assim também os multiplos do vetores de espessuras passado
#(12/07/2023)


import time
import random
import numpy as np
import os
import sys
from v1_0_fisics_dumper import *


#inicial parameters
error_ = [0.1, 0.1, 0.1, 0.1, 0.1]
discrete_value_mm = 1
rigidez_lenght_min = 4/1000
rigidez_lenght_max = 15/1000
aco_lenght_min = 1/1000
aco_lenght_max = 15/1000

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

#standards frequency targets
frequency_target = [1774,1524,1452,1025,354]
# frequency_target = [1774,1524,1452,1025,675]
# frequency_target = [2000, 1500, 1000, 700, 200]
# frequency_target = [6000, 3300, 1100, 400, 200]


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

#rate a individual
def fitness(aco, rigidez, correct_ans):
    error = 0
    # print(f"peso: {total_weight}kg")
    # sys.exit()
    
    #Limitation of weight values part
    total_weight = weight_calculate(aco, rigidez)
    if(total_weight < 4 or total_weight > 9):
        error = 10**10

    #Limitation of thickness values part  
    for _aco in aco:
        if(_aco[2] < aco_lenght_min or _aco[2] > aco_lenght_max):
            error = 10**10
    for _rigidez in rigidez:
        if(_rigidez[2] < rigidez_lenght_min or _rigidez[2] > rigidez_lenght_max):
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
    for _ in range(generation_size):
        list1 = [
            0.001*random.randint(round(rigidez_lenght_min*1000),round(rigidez_lenght_max*1000)),
            0.001*random.randint(round(rigidez_lenght_min*1000),round(rigidez_lenght_max*1000)),
            0.001*random.randint(round(rigidez_lenght_min*1000),round(rigidez_lenght_max*1000)),
            0.001*random.randint(round(rigidez_lenght_min*1000),round(rigidez_lenght_max*1000)),
            0.001*random.randint(round(rigidez_lenght_min*1000),round(rigidez_lenght_max*1000)),
            ]
        list2 = [
            0.001*random.randint(round(aco_lenght_min*1000),round(aco_lenght_max*1000)),
            0.001*random.randint(round(aco_lenght_min*1000),round(aco_lenght_max*1000)),
            0.001*random.randint(round(aco_lenght_min*1000),round(aco_lenght_max*1000)),
            0.001*random.randint(round(aco_lenght_min*1000),round(aco_lenght_max*1000)),
            0.001*random.randint(round(aco_lenght_min*1000),round(aco_lenght_max*1000)),
            ]
        _rigidez.append(list1)
        _aco.append(list2)
        
    return _rigidez, _aco 

#for now, the loop function
def selection_function(p_rigidez, p_aco, correct_ans, limit_generations, generation_size):
    assert len(p_rigidez) == len(p_aco), "Vetor de rigidezes e acos com tamanhos diferentes"
    
    #assigned the first tuple for compare 
    rigidez, aco = parametros(p_rigidez[0], p_aco[0])
    parcial_vector = fitness(aco, rigidez, correct_ans)
    precision = parcial_vector[0]
    vector_errors = parcial_vector[1]
    vector_ans = parcial_vector[2]
    best_tuple = (precision, rigidez, aco, vector_errors, vector_ans)

    start = time.time()
    for i in range(limit_generations):
        rankedsolutions = []

        #creates individuals (tuples) from the measures (p_rigidez, p_aco)
        for j in range(len(p_rigidez)):
            rigidez, aco = parametros(p_rigidez[j], p_aco[j])
            parcial_vector = fitness(aco, rigidez, correct_ans)
            precision = parcial_vector[0]
            vector_errors = parcial_vector[1]
            vector_ans = parcial_vector[2]
            if(precision != 0 or len(rankedsolutions) < 10): # menor then 10 because we chose between the 10 best, so its a guarantee that rankedsolution will have 10 size
                rankedsolutions.append((precision, rigidez, aco, vector_errors, vector_ans)) #tuple contains the value of result (acuracy) and rididez and aco vector
        
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
        os.system('cls' if os.name == 'nt' else 'clear')
        print(f"Best until now:")
        print(f"  Accuracy:          {round(best_tuple[0], 4)}")
        print(f"  Answer (Hz):       {[int(freq) for freq in best_tuple[4]]}")
        print(f"  Vector error (%):  {[round(er*100, 2) for er in best_tuple[3]]}")
        print(f"  Average error (%): {round(np.sum(best_tuple[3])/5*100, 4)}")
        print(f"  Spring (mm):       {[round(er[2]*1000, 2) for er in best_tuple[1]]}")
        print(f"  Mass (mm):         {[round(er[2]*1000, 2) for er in best_tuple[2]]}")
        print()
        print(f"=== Gen {i+1} bests solutions ===")
        for j in range(3):
            aux_vector_error = rankedsolutions[j][3]
            aux_error = np.sum(aux_vector_error)/5*100
            total_weight = weight_calculate(rankedsolutions[j][2], rankedsolutions[j][1])
            # print(f"Error: {round(aux_error, 2)}% and vector_error: {[round(100*er, 2) for er in rankedsolutions[j][3]]}%")
            # print(f"Average Error: {round(aux_error, 2)}% and Weight: {round(total_weight, 2)}kg")
            print(f"Accuracy: {round(rankedsolutions[0][0], 4)} and Weight: {round(total_weight, 2)}kg")
            # print(f"Error: {[round(er, 2) for er in rankedsolutions[j][3]]}% and Weight: {round(total_weight, 2)}kg")
        
        best_error = rankedsolutions[0][3]
        if  (best_error[0] < error_[0] and best_error[1] < error_[1] and best_error[2] < error_[2] and best_error[3] < error_[3] and best_error[4] < error_[4]):
            best_tuple = rankedsolutions[0]
            print("Preparing results")
            # print("Preparing results", end="")
            time.sleep(1.5)
            for _ in range(3):
                print(".")
                time.sleep(0.6)
            break

        p_rigidez, p_aco = mutation_function(crossover_function(rankedsolutions[:10]), generation_size)
        # time.sleep(1.5)

    #print the final solution at end of the limit generation
    end = time.time()
    # os.system('cls' if os.name == 'nt' else 'clear')
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
    print(f"Average error: {round(average_error*100, 4)}%")
    print(f"Error per frequency: {[round(err*100, 2) for err in best_tuple[3]] }%")
    print()

    total_weight = weight_calculate(best_tuple[2], best_tuple[1])
    print(f"Weight: {round(total_weight, 2)}kg")

    rigidez_mm = []
    aco_mm = []
    for s in best_tuple[1]:
        rigidez_mm.append(s[2]*1000)
    for s in best_tuple[2]:
        aco_mm.append(s[2]*1000)
    print(f"Spring thickness(mm): {[round(r, 2) for r in rigidez_mm]}")#thickness = espessura
    print(f"Mass thickness(mm): {[round(r, 2) for r in aco_mm]}")
    print()

    print(f"Finished in {round(end-start, 2)}s")
    return

#mix thickness between individuals
def crossover_function(bestsolutions):
    element_rigidez = []#array of thickness
    element_aco = []#array of thickness
    #create both arrays from tuple to vectors
    for s in bestsolutions:
        _rigidez = []
        _aco = []
        for i in range(len(s[1])):
            _rigidez.append(s[1][i][2])
            _aco.append(s[2][i][2])
        element_rigidez.append(_rigidez)
        element_aco.append(_aco)

    original_rigidez_thickness = np.copy(element_rigidez)
    original_aco_thickness = np.copy(element_aco)

    crossover_rigidez = []
    crossover_aco = []
    for i in range(10):
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
        crossover_rigidez.append(new_rigidez)
        crossover_aco.append(new_aco)
                
    return original_rigidez_thickness, original_aco_thickness, crossover_rigidez, crossover_aco

#add a small rand value or select another possible thickness
def mutation_function(elements, generation_size):
    ranked_rigidez, ranked_aco, crossover_rigidez, crossover_aco = elements
    new_rigidez = []
    new_aco = []
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
            new_lenght_aco = abs(solutions_aco[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
            while new_lenght_aco < 0.000001:
                new_lenght_aco = abs(solutions_aco[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
            one_aco.append(round(new_lenght_aco, 6)) #current number +- 0.001 or 0.002 ....
        
        for j in range(len(solutions_rigidez[0])):
            new_lenght_rigidez = abs(solutions_rigidez[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
            while new_lenght_rigidez < 0.000001:
                new_lenght_rigidez = abs(solutions_rigidez[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(0, 3)))
            one_rigidez.append(round(new_lenght_rigidez, 6)) #current number +- 0.001 or 0.002 ....
        
        new_rigidez.append(one_rigidez)
        new_aco.append(one_aco)
    for ri in ranked_rigidez:
        new_rigidez.append(ri)
    for ac in ranked_aco:
        new_aco.append(ac)
    return new_rigidez, new_aco


#--------------------------teste select_function-------------------------------------
print("--------------------------teste selection_function-------------------------------------")
rigidez2, aco2 = generate_new_solution(150)
#parameters         [L,C,tmola,Eepdm],  [L,C,taco], [Hz, Hz, Hz, Hz, Hz],   limit_generation,   generation_size
selection_function  (rigidez2,          aco2,       frequency_target,       300,                200)