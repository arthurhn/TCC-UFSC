#primeiro código funcional que tenho salvo, nele ocorre ja a mutação, 
#ja usando expovariate pra selecionar, porém ainda sem crossover.
#Erro quadrado, ainda sem dar os pesos nas frequencias.
#Organização bem ruim, sem separar os bibliotecas, o o print durante e final
# com informações quase nulas a respeito do atenuador, além de não salvar o melhor no
# final, apenas exibe o melhor da ultima geração
#(10/05/2023)

import time
import random
import numpy as np
from numpy import linalg as LA
import os

def parametros(tmola, taco):
    assert len(tmola) == len(taco), "Parametros: Numero de molas diferente do numero de massas"
    #rigdez = (L,C,t,E,m)
    rigidez = np.zeros([len(tmola),4])
    aco = np.zeros([len(taco),3])
    L = 0.49 #comprimento
    C = 0.057 #largura

    Et      = 3.5e6#elasticidade tapete
    Eepdm    = 2.3e6#elasticidade (fitas) Pa

    for i in range(len(tmola)-1):
        rigidez[i] = np.array([L,C,tmola[i],Eepdm]) #rigidez[0][2] -> espessura
    rigidez[len(tmola)-1] = np.array([L,C, tmola[len(tmola)-1],Et])

    for i in range(len(taco)):
        aco[i] = np.array([L,C,taco[i]])


    return rigidez, aco

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

def main_function(aco, rigidez):
    resp =  freq(criaMatrizes(calculaRigMass(aco,rigidez, rho_M, rho_K)))
    return resp[0] 

def foo(x, y, z):
    return 6*x**3 + 9*y**2 + 90*z - 25

def fitness(aco, rigidez, correct_ans):
    ans = main_function(aco, rigidez)
    ans = np.sort(ans)
    ans = ans[::-1]
    #correct_asn = [1917.53874113, 1374.28870256, 1071.3959315, 602.29675343, 181.45124695]
    #calculando o erro como medio quadratico
    error = ((ans[0]-correct_ans[0])**2)/correct_ans[0] + ((ans[1]-correct_ans[1])**2)/correct_ans[1] + ((ans[2]-correct_ans[2])**2)/correct_ans[2] + ((ans[3]-correct_ans[3])**2)/correct_ans[3] + ((ans[4]-correct_ans[4])**2)/correct_ans[4]
    if error == 0:
        return 9999999999
    else:
        return abs(1/error)

#cria o primeiro conjunto de soluções
def generate_new_solution(generation_size):
    _aco = []
    _rigidez = []
    for _ in range(generation_size):
        list1 = [
            random.uniform(0.005, 0.5),
            random.uniform(0.005, 0.5),
            random.uniform(0.005, 0.5),
            random.uniform(0.005, 0.5),
            random.uniform(0.005, 0.5),
            ]
        list2 = [
            random.uniform(0.005, 0.5),
            random.uniform(0.005, 0.5),
            random.uniform(0.005, 0.5),
            random.uniform(0.005, 0.5),
            random.uniform(0.005, 0.5),
            ]
        list1 = np.sort(list1)
        list1 = list1[::-1]
        _rigidez.append(list1)
        _aco.append(list2)
        
    return _rigidez, _aco 

def selection_function(p_rigidez, p_aco, correct_ans, limit_generations, generation_size):
    assert len(p_rigidez) == len(p_aco), "Vetor de rigidezes e acos com tamanhos diferentes"
    start = time.time()
    for i in range(limit_generations):
        rankedsolutions = []
        for j in range(len(p_rigidez)):
            rigidez, aco = parametros(p_rigidez[j], p_aco[j])
            rankedsolutions.append((fitness(aco, rigidez, correct_ans), rigidez, aco)) #tuple contains the value of result (acuracy) and rididez and aco vector
        rankedsolutions.sort()
        rankedsolutions = rankedsolutions[::-1]

        os.system('cls' if os.name == 'nt' else 'clear')
        print(f"=== Gen {i+1} bests solutions ===")
        for j in range(5):
            print(rankedsolutions[j][0])
        if rankedsolutions[0][0] > 10:
            p_rigidez = []
            p_rigidez.append([
                rankedsolutions[0][1][0][2],
                rankedsolutions[0][1][1][2],
                rankedsolutions[0][1][2][2],
                rankedsolutions[0][1][3][2],
                rankedsolutions[0][1][4][2]
                            ])
            p_aco = []
            p_aco.append([
                rankedsolutions[0][2][0][2],
                rankedsolutions[0][2][1][2],
                rankedsolutions[0][2][2][2],
                rankedsolutions[0][2][3][2],
                rankedsolutions[0][2][4][2]
                            ])
            break
        p_rigidez, p_aco = mutation_function(crossover_function(rankedsolutions[:50]), generation_size)
    end = time.time()
    print()
    print(f"Expected frequencys(Hz): {correct_ans}")
    tmola, taco = parametros(p_rigidez[0], p_aco[0])
    ans_frequency = main_function(taco, tmola)
    print(f"Obtained frequencys(Hz): {ans_frequency}")
    print()
    average_error = 0
    for i in range(len(correct_ans)):
        average_error += abs((ans_frequency[i]-correct_ans[i])/correct_ans[i])
    average_error = average_error/len(correct_ans)
    print(f"Average error: {round(average_error*100, 4)}%")
    print()
    #print(f"Spring thickness(m): {p_rigidez[0]}")#thickness = espessura
    #print(f"Mass thickness(m): {p_aco[0]}")
    rigidez_mm = []
    aco_mm = []
    for s in p_rigidez[0]:
        rigidez_mm.append(s*1000)
    for s in p_aco[0]:
        aco_mm.append(s*1000)
    print(f"Spring thickness(mm): {rigidez_mm}")#thickness = espessura
    print(f"Mass thickness(mm): {aco_mm}")
    print()

    print(f"Finished in {end-start}s")
    return

    # print(f"obtained frequencys: {}")
    return

def crossover_function(bestsolutions):
    element_rigidez = []#array of thickness
    element_aco = []#array of thickness
    for s in bestsolutions:
        _rigidez = []
        _aco = []
        for i in range(len(s[1])):
            _rigidez.append(s[1][i][2])
            _aco.append(s[2][i][2])
        element_rigidez.append(_rigidez)
        element_aco.append(_aco)
    # print(f"len(bestsolutions): {len(bestsolutions)}")
    # print(f"element_rigidez: {element_rigidez}")
    # print(f"element_aco:{element_aco}")
    return element_rigidez, element_aco

def mutation_function(elements, generation_size):
    ranked_rigidez, ranked_aco = elements
    new_rigidez = []
    new_aco = []
    # print(f"ranked_rigidez: {ranked_rigidez}")
    # print(f"ranked_aco: {ranked_aco}")
    # return p_rigidez, p_aco
    assert len(ranked_rigidez) == len(ranked_aco), "Vetor p_ridizes e p_aco com tamanhos diferentes, mutation_function"
    
    #parte que limita valores para as molas -------------------------------
    # removidas = 0
    # for i in range(len(ranked_rigidez)):
    #     # print(f"i: {i-removidas}")
    #     for j in range(len(ranked_rigidez[i-removidas])):
    #         if(ranked_rigidez[i-removidas][j] < 0.0030 or ranked_rigidez[i-removidas][j] > 0.8 or ranked_aco[i-removidas][j] < 0.0030 or ranked_aco[i-removidas][j] > 0.8):#tem que adicionar o aco aqui ainda
    #             # print(f"removeu[{i-removidas}][{j}]")
    #             ranked_rigidez.pop(i-removidas)
    #             ranked_aco.pop(i-removidas)
    #             j = len(ranked_rigidez)
    #             removidas += 1
    #             break
    # if(len(ranked_rigidez) == 0):
    #     print("deletou todos!")

    for _ in range(generation_size):
        one_rigidez = []
        one_aco = []
        #usando distribuição exponencial pra pegar as melhores soluções, ja que elas estão ordenadas da ma=elhor solução para pior
        v = [] 
        size_array = len(ranked_rigidez)-1
        for _ in range(size_array): 
            temp = random.expovariate(0.000001)
            v.append(temp) 
        v.sort(reverse=True)
        normalized_v = v/np.linalg.norm(v)
        normalized_v = size_array*normalized_v/normalized_v[0]
        choice = [int(i) for i in normalized_v]
        i = random.choice(choice)#escolhendo uma das melhores amostrar
        #------------------------------------------------------------------------------------------
        # i = random.randint(0, len(ranked_rigidez)-1)#escolhendo uma das melhores amostrar (metodo antigo)
        for j in range(len(ranked_rigidez[0])):
            # print(f"ranked_rigidez[{i}][{j}]:{ranked_rigidez[i][j]}")
            one_rigidez.append(ranked_rigidez[i][j] * random.uniform(0.9, 1.1)) 
        for j in range(len(ranked_rigidez[0])):
            # print(f"ranked_aco[{i}][{j}]:{ranked_aco[i][j]}")
            one_aco.append(ranked_aco[i][j] * random.uniform(0.9, 1.1))
        new_rigidez.append(one_rigidez)
        new_aco.append(one_aco)
    # print(f"new_rigidez: {new_rigidez}")
    # print(f"new_aco: {new_aco}")
    return new_rigidez, new_aco



#--------------------------teste select_function-------------------------------------
print("--------------------------teste selection_function-------------------------------------")
#[L,C,tmola,Eepdm], [L,C,taco], [Hz, Hz, Hz, Hz, Hz], limit_generation, generation_size
rigidez2, aco2 = generate_new_solution(500)
selection_function(rigidez2, aco2, [2000, 1500, 1000, 700, 200], 500, 150)

#deixar a mola(borracha), todas elas de 1mm
#varias as chapas de aço, com variação de 0.5 em 0.5mm
#limitar as espessuras do aço de 1 a 8mm
#não importa a ordem das frequencias da resposta, ordenar do maior pro menor pra comparar 
#borrachas temos espesura de 1 em 1mm