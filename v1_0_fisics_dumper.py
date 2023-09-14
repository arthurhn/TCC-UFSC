import numpy as np
from numpy import linalg as LA

L = 0.49 #comprimento
C = 0.050 #largura
Et      = 3.5e6#elasticidade tapete
Eepdm    = 2.3e6#elasticidade (fitas) Pa (C101/C)
rho_M=7800#densidade massa
rho_K=1300#densidade mola(fita)

def parametros(tmola, taco):
    assert len(tmola) == len(taco), "Parametros: Numero de molas diferente do numero de massas"
    #rigdez = (L,C,t,E,m)
    rigidez = np.zeros([len(tmola),4])
    aco = np.zeros([len(taco),3])

    for i in range(len(tmola)):
        rigidez[i] = np.array([L,C,tmola[i],Et]) #rigidez[0][2] -> espessura
    # rigidez[len(tmola)-1] = np.array([L,C, tmola[len(tmola)-1],Et])

    for i in range(len(taco)):
        aco[i] = np.array([L,C,taco[i]])


    return rigidez, aco

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

def weight_calculate(aco, rigidez):

    volume_aco = [aco[i][2]*L*C for i in range(5)]
    volume_rigidez = [rigidez[i][2]*L*C for i in range(5)]
    array_weight_aco = [volume_aco[i]*rho_M for i in range(5)]
    array_weight_rigidez = [volume_rigidez[i]*rho_K for i in range(5)]
    weight_aco_total = np.sum(array_weight_aco)
    weight_rigidez_total = np.sum(array_weight_rigidez)
    return (weight_aco_total+weight_rigidez_total)
