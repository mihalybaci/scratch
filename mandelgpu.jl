using CUDA
using BenchmarkTools

function escapetime(z; maxiter=80)
    c = z
    for n = 1:maxiter
        if abs(z) > 2
            return n-1
        end
        z = z^2 + c
    end
    return maxiter % UInt8
end

# ╔═╡ e646b05a-c0e6-4768-8062-186492a10ddd
"""
Calculate the escape time for each grid point (pixel)
"""
function mandel(; width=80, height=20, maxiter=60)
    out = zeros(Int, height, width)
    real = range(-2.0, 0.5, length=width)
    imag = range(-1.0, 1.0, length=height)*im
    for x in 1:width
        for y in 1:height
            z = real[x] + imag[y]
            out[y,x] = escapetime(z, maxiter=maxiter)
        end
    end
    return out
end

function mandelspawn(; width=80, height=20, maxiter=80)
    out = zeros(Int32, height, width)
    real = range(-2.0, 0.5, length=width)
    imag = range(-1.0, 1.0, length=height)*im
    @sync for x in 1:width
        Threads.@spawn for y in 1:height
            z = real[x] + imag[y]
            out[y,x] = escapetime(z, maxiter=maxiter)
        end
    end
    return out
end

function test(in, out)
    out .= escapetime.(in, maxiter=80)
    synchronize(out)
end


width = 600
height = 450
maxiter = 18

@benchmark mandel(width=width, height=height, maxiter=maxiter)  #  ms
@benchmark mandelspawn(width=width, height=height, maxiter=maxiter)  # 62 ms


function escape(z0, maxiter)
    c = ComplexF64(0.5, 0.75)
    z = z0
    for i ∈ 1:maxiter
        abs2(z) > 4f0 && return (i-1) % UInt8
         z = z*z + c
    end
    return maxiter % UInt8
end

function run!(in, out; maxiter=16)
    out .= escape.(in, maxiter)
end

w, h = 450, 600

q =  CuArray([ComplexF64(real, imag) for imag in range(-2.0, 0.5, length=w), real in range(-1.0, 1.0, length=h)])

result = CuArray(zeros(UInt8, size(q)))

function juliaset(;width=80, height=20, maxiter=60)
    q =  CuArray([ComplexF64(real, imag) for imag in range(-2.0, 0.5, length=width), real in range(-1.0, 1.0, length=height)])
    result = CuArray(zeros(UInt8, size(q)))
    run!(q, result, maxiter=maxiter)
    return result
end
