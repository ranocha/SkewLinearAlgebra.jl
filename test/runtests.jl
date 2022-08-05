using LinearAlgebra, Random
import SkewLinearAlgebra as SLA
using Test

Random.seed!(314159) # use same pseudorandom stream for every test

@testset "SkewLinearAlgebra.jl" begin
    for n in [2,20,153,200]
        A=SLA.skewhermitian(randn(n,n))
        @test SLA.isskewhermitian(A)
        @test SLA.isskewhermitian(A.data)
        B=2*Matrix(A)
        @test SLA.isskewhermitian(B)

        @test A==copy(A)::SLA.SkewHermitian
        @test size(A)==size(A.data)
        @test size(A,1)==size(A.data,1)
        @test size(A,2)==size(A.data,2)
        @test Matrix(A)==A.data
        @test tr(A)==0
        @test (-A).data==-(A.data)
        A2 = A.data*A.data
        @test A*A == A2 ≈ Symmetric(A2)
        @test A*B == A.data*B
        @test B*A == B*A.data
        if iseven(n) # for odd n, a skew-Hermitian matrix is singular
            @test inv(A)::SLA.SkewHermitian ≈ inv(A.data)
        end
        @test (A*2).data ==A.data*2
        @test (2*A).data ==2*A.data
        @test (A/2).data == A.data/2
        C=A+A
        @test C.data==A.data+A.data
        B=SLA.SkewHermitian(B)
        C=A-B
        @test C.data==-A.data
        B=triu(A)
        @test B≈triu(A.data)
        B=tril(A,n-2)
        @test B≈tril(A.data,n-2)
        k=dot(A,A)
        B=Matrix(A)
        for i=1:n
            for j=1:n
                B[i,j]*=B[i,j]
            end
        end
        @test k≈sum(B)

        if n>1
            @test getindex(A,2,1)==A.data[2,1]
        end

        setindex!(A,3,n,n-1)
        @test getindex(A,n,n-1)==3
        @test getindex(A,n-1,n)==-3
        @test parent(A)== A.data

        x=randn(n)
        y=zeros(n)
        mul!(y,A,x,2,0)
        @test y==2*A.data*x
        k=dot(y,A,x)
        @test k≈ transpose(y)*A.data*x
        k=copy(y)
        mul!(y,A,x,2,3)
        @test y≈2*A*x+3*k
        B=copy(A)
        copyto!(B,A)
        @test B==A
        B=Matrix(A)
        @test B==A.data
        C=similar(B,n,n)
        mul!(C,A,B,2,0)
        @test C==2*A.data*B
        mul!(C,B,A,2,0)
        @test C==2*B*A.data
        B=SLA.SkewHermitian(B)
        mul!(C,B,A,2,0)
        @test C==2*B.data*A.data
        A.data[n,n]=4
        @test SLA.isskewhermitian(A.data)==false
        A.data[n,n]=0
        A.data[n,1]=4
        @test SLA.isskewhermitian(A.data)==false
        #LU=lu(A)
        #@test LU.L*LU.U≈A.data
        LQ=lq(A)
        @test LQ.L*LQ.Q≈A.data
        QR=qr(A)
        @test QR.Q*QR.R≈A.data
        F=schur(A)
        @test A.data ≈ F.vectors * F.Schur * F.vectors'
    end
end
@testset "hessenberg.jl" begin
    for n in [2,20,153,200]
        A=SLA.skewhermitian(randn(n,n))
        B=Matrix(A)
        HA=hessenberg(A)
        HB=hessenberg(B)
        @test Matrix(HA.H)≈Matrix(HB.H)
        if n>1
            Q=SLA.getQ(HA)
            @test Q≈HB.Q
        end
    end
    """
    A=zeros(4,4)
    A[2:4,1]=ones(3)
    A[1,2:4]=-ones(3)
    A=SLA.SkewHermitian(A)
    B=Matrix(A)
    HA=hessenberg(A)
    HB=hessenberg(B)
    @test Matrix(HA.H)≈Matrix(HB.H)
    """
end
@testset "eigen.jl" begin
    for n in [2,20,153,200]
        A=SLA.skewhermitian(randn(n,n))
        B=Matrix(A)

        valA = imag(eigvals(A))
        valB = imag(eigvals(B))
        sort!(valA)
        sort!(valB)
        @test valA ≈ valB
        Eig=eigen(A)
        valA=Eig.values
        Qr=Eig.realvectors
        Qim=Eig.imagvectors
        valB,Q = eigen(B)
        Q2 = Qr + Qim.*1im
        @test real(Q2*diagm(valA)*adjoint(Q2))≈A.data
        valA=imag(valA)
        valB=imag(valB)
        sort!(valA)
        sort!(valB)
        @test valA ≈ valB
        Svd=svd(A)
        @test Svd.U*Diagonal(Svd.S)*Svd.Vt≈A.data
        @test svdvals(A)≈svdvals(B)
    end
end
@testset "exp.jl" begin

    for n in [2,20,153,200]
        A=SLA.skewhermitian(randn(n,n))
        B=Matrix(A)
        @test exp(B)≈exp(A)
        @test cis(A)≈exp(Hermitian(A.data*1im))
        @test cos(B)≈cos(A)
        @test sin(B)≈sin(A)
        #@test tan(B)≈tan(A)
        @test sinh(B)≈sinh(A)
        @test cosh(B)≈cosh(A)
        @test tanh(B)≈tanh(A)
    end
end
