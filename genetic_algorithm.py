#Mesma descrição do 1.1.0, porém nesse código as espessuras das borrachas/molas são fixas (passadas na main function)
#Aqui o fitness já considera alguns parametros de requisitos, como peso e tamanhos min e max
#das espessuras. Discretização e outros requisitos ja sendo passados no argv, porém ainda com erro médio
#(12/05/2023)
import time
import random
import numpy as np
from numpy import linalg as LA
import os
import sys

porcentage_error_target = 5
discrete_value_mm = 1
if(len(sys.argv) >= 3):
    porcentage_error_target = float(sys.argv[1])/100
    discrete_value_mm = float(sys.argv[2])
    if(porcentage_error_target == 0):
        porcentage_error_target = 5
    if(discrete_value_mm == 0):
        discrete_value_mm = 1
#accuracy
error_ = (porcentage_error_target)**2
accuracy_target = 1/error_

discrete_value = discrete_value_mm/1000
# frequency_target = [2000, 1500, 1000, 700, 200]
frequency_target = [1820, 1345, 1021, 641, 300]
# frequency_target = [1822.38397854, 1432.4870541, 741.5716060, 446.82140177, 143.35308754]
#requency_target = [1822, 1432, 741, 446, 143]
# frequency_target = [6000, 3300, 1100, 400, 200]

def parametros(taco):
    assert 5 == len(taco), "Parametros: Numero de massas diferente de 5"
    #rigdez = (L,C,t,E,m)
    aco = np.zeros([len(taco),3])
    L = 0.49 #comprimento
    C = 0.057 #largura

    for i in range(len(taco)):
        aco[i] = np.array([L,C,taco[i]])

    return aco

rho_M=7800#densidade massa
rho_K=1300#densidade mola(fita)

#aco,rigidez, rho_M, rho_K
def calculaRigMass(dim_mass,dim_rig,rho_mass,rho_rig):
    assert type(dim_rig)==np.ndarray, "calculaRigsMass: 'Matriz elementos de rigidez não é um numpy.array'"
    assert type(dim_rig)==np.ndarray, "calculaRigsMass: 'Matriz elementos de massa não é um numpy.array'"
    row_mass,col_mass = dim_mass.shape
    row_rig,col_rig = dim_rig.shape
    assert row_mass==row_rig, "calculaRigsMass: 'Número de massas diferente do número de rigidezes'"
    assert col_mass==3 and col_rig==4, "calculaRigsMass: 'Número de colunas incorreto'"
    assert rho_mass>0 and rho_rig>0, "calculaRigsMass: 'Densidade não pode assumir valores negativos ou nulos'"
    
    n = row_mass
    k = np.zeros(n)
    m = np.zeros(n)
    for a in range(n):
        k[a] = dim_rig[a,0]*dim_rig[a,1]*dim_rig[a,3]/dim_rig[a,2]
        m[a] = dim_mass[a,0]*dim_mass[a,1]*dim_mass[a,2]*rho_mass + dim_rig[a,0]*dim_rig[a,1]*dim_rig[a,2]*rho_rig
    return (m,k)

def criaMatrizes(dados):
    m,k = dados
    n_mass = len(m)
    n_rig = len(k)
    assert n_rig == n_mass, "criaMatrizes: 'Número de massas diferente do número de rigidezes'"
    
    n = n_rig
    M = np.zeros([n,n])
    K = np.zeros([n,n])
    for a in range(n):
        M[a,a] = m[a]
        if a!=0: K[a,a-1] = -k[a]
        if a==n-1: K[a,a] = k[a]
        else: K[a,a] = k[a] + k[a+1]
        if a!=(n-1): K[a,a+1] = -k[a+1]
    return M,K
    
def freq(dados):
    M,K = dados
    assert type(M)==np.ndarray, "freq: 'Matriz de massa não é um numpy.array'"
    assert type(K)==np.ndarray, "freq: 'Matriz de rigidez não é um numpy.array'"
    row_M,col_M = M.shape
    row_K,col_K = K.shape
    assert row_M==col_M, "freq: 'Matriz de massa não quadrada' "
    assert row_K==col_K, "freq: 'Matriz de rigidez não quadrada' "
    assert row_M==row_K, "freq: 'Matrizes de massa e rigidez de ordens diferentes.'"
    
    n = row_M
    M_1 = LA.inv(M)
    zero = np.zeros([n,n])
    ident = np.eye(n)
    
    primeira = np.concatenate([zero,ident],axis = 1)
    segunda = np.concatenate([-M_1 @ K, zero],axis=1)
    A = np.concatenate([primeira,segunda])#matriz gigante de 4 parte (5x5), a11->zeros, a12->inv, a21->calculos em inv, a22-> zeros 
    u,v = LA.eig(A)#u = autovalor, v=autovetor
    
    ##aqui em baixo ele vai pegar somente a parte img do autovalor e apenas os positivos (metade do vetor), depois disso, transformar de rad pra Hz
    w = u.imag
    f = np.zeros(len(w))
    f_pos = np.zeros(int(len(w)/2))
    j=0
    for i in range(0,len(w)):
        f[i] = w[i]/(2*3.14)
        if f[i]>0:
            f_pos[j] = f[i]
            j+=1
    return f_pos,v#f_pos -> frequencias de oscilação (em Hz) de cada massa

def main_function(aco):
    L = 0.49
    C = 0.057
    Et      = 3.5e6#elasticidade tapete
    Eepdm    = 2.3e6#elasticidade (fitas) Pa
    #rigdez = (L,C,t,E,m)
    rigidez = np.zeros([5,4])
    rigidez[0] = np.array([L,C,0.004,Eepdm])
    rigidez[1] = np.array([L,C,0.002,Eepdm])
    rigidez[2] = np.array([L,C,0.002,Eepdm])
    rigidez[3] = np.array([L,C,0.002,Eepdm])
    rigidez[4] = np.array([L,C,0.001,Et])
    resp =  freq(criaMatrizes(calculaRigMass(aco,rigidez, rho_M, rho_K)))
    return resp[0] 

def fitness(aco, correct_ans):
    ans = main_function(aco)
    ans = np.sort(ans)
    ans = ans[::-1]
    #correct_asn = [1917.53874113, 1374.28870256, 1071.3959315, 602.29675343, 181.45124695]
    #calculando o erro como medio quadratico
    error = (((ans[0]-correct_ans[0])/correct_ans[0])**2 + ((ans[1]-correct_ans[1])/correct_ans[1])**2 + ((ans[2]-correct_ans[2])/correct_ans[2])**2 + ((ans[3]-correct_ans[3])/correct_ans[3])**2 + ((ans[4]-correct_ans[4])/correct_ans[4])**2)/len(correct_ans)
    if error == 0:
        return 9999999999
    else:
        return abs(1/error)

#cria o primeiro conjunto de soluções
def generate_new_solution(generation_size):
    _aco = []
    for _ in range(generation_size):
        list2 = [
            0.001*random.randint(2,15),
            0.001*random.randint(2,15),
            0.001*random.randint(2,15),
            0.001*random.randint(2,15),
            0.001*random.randint(2,15),
            ]
        _aco.append(list2)
    return _aco 

def selection_function(p_aco, correct_ans, limit_generations, generation_size):
    start = time.time()
    for i in range(limit_generations):
        rankedsolutions = []
        for j in range(len(p_aco)):
            aco = parametros(p_aco[j])
            rankedsolutions.append((fitness(aco, correct_ans), aco)) #tuple contains the value of result (acuracy) and rididez and aco vector
        
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

        os.system('cls' if os.name == 'nt' else 'clear')
        print(f"=== Gen {i+1} bests solutions ===")
        for j in range(5):
            aux_error = 1/rankedsolutions[j][0]
            aux_porcentage = np.sqrt(aux_error)*100
            print(f"Error: {round(aux_porcentage, 2)}%")
        
        if rankedsolutions[0][0] > accuracy_target:
            p_aco = []
            p_aco.append([
                rankedsolutions[0][1][0][2],
                rankedsolutions[0][1][1][2],
                rankedsolutions[0][1][2][2],
                rankedsolutions[0][1][3][2],
                rankedsolutions[0][1][4][2]
                            ])
            break
        p_aco = mutation_function(crossover_function(rankedsolutions[:50]), generation_size)
    end = time.time()
    os.system('cls' if os.name == 'nt' else 'clear')
    print()
    print("====== Best result ======")
    print()
    print(f"Expected frequencys(Hz): {correct_ans}")
    taco = parametros(p_aco[0])
    ans_frequency = main_function(taco)
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
    print()
    #print(f"Spring thickness(m): {p_rigidez[0]}")#thickness = espessura
    #print(f"Mass thickness(m): {p_aco[0]}")
    aco_mm = []
    for s in p_aco[0]:
        aco_mm.append(s*1000)
    print(f"Spring thickness(mm): {[4, 2, 2, 2, 1]}")#thickness = espessura
    print(f"Mass thickness(mm): {[round(a, 3) for a in aco_mm]}")
    print()

    print(f"Finished in {round(end-start, 2)}s")
    return

    # print(f"obtained frequencys: {}")
    return

def crossover_function(bestsolutions):
    element_aco = []#array of thickness
    for s in bestsolutions:
        _aco = []
        for i in range(len(s[1])):
            _aco.append(s[1][i][2])
        element_aco.append(_aco)
    # print(f"len(bestsolutions): {len(bestsolutions)}")
    # print(f"element_rigidez: {element_rigidez}")
    # print(f"element_aco:{element_aco}")
    return element_aco

def mutation_function(elements, generation_size):
    ranked_aco = elements
    new_aco = []
    
    # parte que limita valores para as molas -------------------------------
    # removidas = 0
    # for i in range(len(ranked_aco)):
    #     # print(f"i: {i-removidas}")
    #     for j in range(len(ranked_aco[i-removidas])):
    #         if(ranked_aco[i-removidas][j] < 0.002 or ranked_aco[i-removidas][j] > 0.015):#tem que adicionar o aco aqui ainda
    #             # print(f"removeu[{i-removidas}][{j}]")
    #             ranked_aco.pop(i-removidas)
    #             j = len(ranked_aco)
    #             removidas += 1
    #             break
    # if(len(ranked_aco) < 3):
    #     print("All generation was deleted!")
    #     sys.exit()

    for _ in range(generation_size):
        one_aco = []
        #usando distribuição exponencial pra pegar as melhores soluções, ja que elas estão ordenadas da ma=elhor solução para pior
        v = [] 
        size_array = len(ranked_aco)-1
        for _ in range(size_array): 
            temp = random.expovariate(0.000001)
            v.append(temp) 
        v.sort(reverse=True)
        normalized_v = v/np.linalg.norm(v)
        normalized_v = size_array*normalized_v/normalized_v[0]
        choice = [int(i) for i in normalized_v]
        i = random.choice(choice)#escolhendo uma das melhores amostrar
        # i = random.randint(0, len(ranked_rigidez)-1)#escolhendo uma das melhores amostrar (metodo antigo)
        #------------------------------------------------------------------------------------------
        signal = [-1, 1]
        for j in range(len(ranked_aco[0])):
            # print(f"ranked_rigidez[{i}][{j}]:{ranked_rigidez[i][j]}")
            new_lenght_aco = abs(ranked_aco[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(1, 4)))
            while new_lenght_aco < 0.000001:
                new_lenght_aco = abs(ranked_aco[i][j] + signal[random.randint(0, 1)] * (discrete_value * random.randint(1, 4)))
            one_aco.append(round(new_lenght_aco, 6)) #current number +- 0.001 or 0.002 ....
        new_aco.append(one_aco)
    return new_aco



#--------------------------teste select_function-------------------------------------
print("--------------------------teste selection_function-------------------------------------")
#[L,C,tmola,Eepdm], [L,C,taco], [Hz, Hz, Hz, Hz, Hz], limit_generation, generation_size
aco2 = generate_new_solution(500)
selection_function(aco2, frequency_target, 500, 150)

#deixar a mola(borracha), todas elas de 1mm
#varias as chapas de aço, com variação de 0.5 em 0.5mm
#limitar as espessuras do aço de 1 a 8mm
#não importa a ordem das frequencias da resposta, ordenar do maior pro menor pra comparar 
#borrachas temos espesura de 1 em 1mm

# print(f"error max: {porcentage_error_target}")