### A Pluto.jl notebook ###
# v0.19.47

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 252baa9e-2a73-434f-a33c-836464dd9b01
using Plots, LinearAlgebra, Optim, DifferentialEquations, PlutoUI, Dates , Statistics

# ╔═╡ 31846f28-a3d2-11ef-1308-dd1e47ea992b
html"""
<h1 style="text-align: center"> Actividad Ajuste de Datos </h1>
"""

# ╔═╡ b022e54e-d9a3-450e-a601-047a57f53b10
md"#### Integrantes: 
* Luis Camilo Gómez Rodríguez.
* Jose Simón Ramos Sandoval.
* Tomas David Rodríguez Agudelo.
"

# ╔═╡ 721ae26b-573f-4b01-8f01-60d65ceeafcf
md"""
**Problema 4:** Construya, para un conjunto de datos seleccionados, un modelo que considere adecuado y ajuste los valores de los parámetros. Es decir, repita el ejercicio arriba [1] para otro conjunto de datos.

Puede usar librerías de aprendizaje de máquina, de interpolación o de ajustes diferentes a las mostradas en clase. Por ejemplo, puede usar los datos de la [tabla anexa](https://saludata.saludcapital.gov.co/osb/index.php/datos-de-salud/enfermedades-trasmisibles/ocupacion-ucis/).
"""

# ╔═╡ a90f228e-2e72-44cb-8b7f-dbea8e53f7fb
md"""
Para desarrollar este problemo utilizaremos las siguientes librerías:
"""

# ╔═╡ 4bd6bcb2-6127-45b9-8032-97a876288fe4
md"""
y utilizaremos los datos sugeridos para el problema, que son la ocupación de camas UCI por Covid-19 de los primeros veinte  días de enero de 2022 en Bogotá [2].
"""

# ╔═╡ fb28df9e-1ea5-4481-a7bd-28300499dfab
data = [
	("1/01/2022",	222),
	("2/01/2022",	209),
	("3/01/2022",	217),
	("4/01/2022",	245),
	("5/01/2022",	252),
	("6/01/2022",	278),
	("7/01/2022",	291),
	("8/01/2022",	299),
	("9/01/2022",	302),
	("10/01/2022",	292),
	("11/01/2022",	311),
	("12/01/2022",	306),
	("13/01/2022",	326),
	("14/01/2022",	332),
	("15/01/2022",	368),
	("16/01/2022",	356),
	("17/01/2022",	373),
	("18/01/2022",	397),
	("19/01/2022",	410),
	("20/01/2022",	431)]

# ╔═╡ 5fceba2f-06eb-4173-8a64-92b4b9ff7b7a
md"""
A continuación separaremos el conjunto de datos en `dates` y `values`. Usamos la librería `Dates` para tipar mejor el conjunto de datos de las fechas (`yyyy/mm/dd`).
"""

# ╔═╡ da658b1f-f72d-48df-b2d2-0de17250219e
dates = [Date(item[1], "dd/mm/yyyy") for item in data]

# ╔═╡ 72f95577-4ec2-4464-a5f8-da59e64523e5
values = [item[2] for item in data]

# ╔═╡ 96ff62f9-ebdf-44a0-b9bd-1703a1f7c4d2
md"""
Visualicemos estos datos:
"""

# ╔═╡ 31fa6de2-b739-4c0e-a46e-cf3736d9d429
plot(dates, values, seriestype=:scatter, ylabel="Cantidad", xlabel="Fecha", legend=false, title="Ocupación de Camas UCI Covid-19", size=(600, 400), color=:red)

# ╔═╡ 5e756abf-619f-44ff-8cdf-273344ce4686
md"""
Notaremos $O(t)$ como la ocupación de camas UCI por Covid-19 en Bogotá en el tiempo $t$, por simplicidad tomaremos:

- 2022-01-01 como el tiempo 1.
- 2022-01-02 como el tiempo 2.
- etc...
"""

# ╔═╡ 8f447492-cbf1-4abc-a542-389add65da81
tiempo = [i for i in 1:length(dates)]

# ╔═╡ d8f88fee-bb8e-4dd1-8deb-c5b070b270b2
html"""
<h2 style="text-align:center">Modelo lineal</h2>
"""

# ╔═╡ dbee1abf-7858-4ace-a339-2fab9064968b
md"""
Para este modelo asumimos que el modelo lineal tiene la forma:

$$O(t)\approx a+bt$$
"""

# ╔═╡ a97e1d99-69fa-44fe-9554-d41f4a2d2dfa
md"""
Queremos estimar los parámetros $a$ y $b$ tales que minimicen la siguiente función que, usando mínimos cuadrados, mide la norma del residuo (tamaño del desajuste entre el modelo lineal y los datos):
"""

# ╔═╡ adb492a3-2d99-4082-b1b9-a421389204df
function residuoMLineal(par, O, t)
	a, b = par
	oneaux = fill(1, size(t))
	Opred = a*oneaux + b*t
	res = O - Opred
	nres = norm(res)
	return nres
end

# ╔═╡ 078a6bf7-8fbb-4cff-93d5-21c96655565a
md"""
Podemos probar con distintos valores de $a$, $b$ y calcular el residuo (Por defecto están los valores óptimos encontrados):
"""

# ╔═╡ 5599267b-a4ed-4995-aa17-7714bbed8e78
begin
	aMlin = @bind aMLinealv Slider(-250:.1:250, show_value=true, default=199.068)
	bMlin = @bind bMLinealv Slider(-20:.1:20, show_value=true, default=10.6459)
	resMLinealv = residuoMLineal([aMLinealv, bMLinealv], values, tiempo)
end;

# ╔═╡ a575e105-2142-460f-9c98-37486e00c361
md"""
a = $aMlin

b = $bMlin

residuo = $resMLinealv
"""

# ╔═╡ f77361b9-a981-412d-8efe-3629c4909985
begin
	plot(tiempo, values, seriestype=:scatter, ylabel="Cantidad", xlabel="Tiempo", legend=true, title="Ocupación de Camas UCI Covid-19 - Modelo Lineal", size=(600, 400), color=:red, label="Ocupación")
	plot!(tiempo, [aMLinealv.+tiempo.*bMLinealv], color=:blue, linewidth=3, label="Modelo lineal")
end

# ╔═╡ 0fbfed51-9df7-4e4f-b63b-354706ed297e
md"""
Utilizando la librería de optimización `Optim`, calculamos el valor aproximado de los parámetros óptimos, para ello, definimos una función que depende solo de la variable de decisión:
"""

# ╔═╡ 9de8ddb3-2185-4846-b2b4-9199bd7a8fb9
rMLineal(par) = residuoMLineal(par, values, tiempo)

# ╔═╡ 80bdb219-86bf-45f3-9409-3ccabb94bf26
md"""
Y la optimizamos, utilizando `Optim.optimize`:
"""

# ╔═╡ 7e1f32a4-3f73-4d7a-bd43-978d5a3b48f2
oLineal = Optim.optimize(rMLineal, [186.0, 12.0], LBFGS())

# ╔═╡ 1391ee0a-bdc7-42a1-b3e4-e7fd521cf727
md"""
Obteniendo los siguientes valores óptimos:
"""

# ╔═╡ 7a957fb4-62a9-4db0-a633-8fa0ee4e13e2
oLineal.minimizer

# ╔═╡ ed3a788c-ad86-49e7-b7b1-6a16e58edf1e
md"""
Y el valor mínimo encontrado es:
"""

# ╔═╡ 7319b980-921b-490c-b4fc-91d52dfc3bd8
oLineal.minimum

# ╔═╡ ce9d24db-954e-43fe-816f-faf3940648a5
md"""
Es decir que la ecuación lineal óptima es

$$O(t) = 199.058 + 10.6459 t.$$
"""

# ╔═╡ 9f78cb4d-5bef-4c12-b565-6be2a313f52c
html"""
<h2 style="text-align:center">Modelo polinomio cúbico</h2>
"""

# ╔═╡ fb244c66-b97a-4c97-8fe5-8056033be405
md"""
En este caso, asumimos que el modelo tiene la forma:

$$O(t)\approx a+bt+ct^2+dt^3$$
"""

# ╔═╡ d2ba97de-01de-4029-8fae-afa845eab2dc
md"""
Queremos estimar los parámetros $a$, $b$, $c$ y $d$ tales que minimicen la siguiente función que mide el desajuste (análoga a la del modelo lineal):
"""

# ╔═╡ 82353f63-0302-4b6f-a4bd-304338a95032
function residuoMcúbico(par, O, t)
	a, b, c, d = par
	oneaux = fill(1, length(t))
	Opred = a*oneaux + b*t + c*t.^2 + d*t.^3
	nres = norm(O-Opred)
	return nres
end

# ╔═╡ 34faf338-5930-47f5-8c55-33797b0dd848
md"""
De manera similar, definimos la función a minimizar que solo depende de los parámetros:
"""

# ╔═╡ 0d6c6587-d3b4-460f-a802-f803372f334d
rMCúbico(par) = residuoMcúbico(par, values, tiempo)

# ╔═╡ 5842dfba-0082-4577-a8b1-4a603ff6cdef
md"""
La optimizamos:
"""

# ╔═╡ 3ef25b10-d59d-4ef0-9260-17d60d79297c
oCúbico = Optim.optimize(rMCúbico, [186.0, 12.0, 10.0, 10.0], LBFGS())

# ╔═╡ 8a707e3b-7987-4e48-acf6-994746282f00
md"""
Encontrando los siguientes valores óptimos:
"""

# ╔═╡ db98d90c-9b21-4de0-8c22-3572b3461b9b
resCu = oCúbico.minimizer

# ╔═╡ 5a9cf26e-553e-482c-918a-c9845f1ec183
md"""
Y el siguiente valor mínimo (mejor que el modelo lineal):
"""

# ╔═╡ f6f7bd9e-7354-4eea-8eb1-bfbabc1a5d13
oCúbico.minimum

# ╔═╡ c0e1b0ee-1c1c-4b22-977f-844358b7f5fe
md"""
Es decir que la ecuación cúbica óptima es

$$O(t) = 185.333+19.8622t+-1.24469t^2+0.0433457t^3$$
"""

# ╔═╡ 3097376f-aad2-42f1-be36-122291ecb83b
md"""
y la podemos visualizar:
"""

# ╔═╡ 6a265d81-58c2-4d3c-9301-e576384c8b94
begin
	plot(tiempo, values, seriestype=:scatter, ylabel="Cantidad", xlabel="Tiempo", legend=true, title="Ocupación de Camas UCI Covid-19 - Modelo cúbico", size=(600, 400), color=:red, label="Ocupación")
	plot!(tiempo, [resCu[1].+tiempo.*resCu[2].+tiempo.^2 .*resCu[3]+tiempo.^3 .*resCu[4]], color=:blue, linewidth=3, label="Modelo cúbico")
end

# ╔═╡ 2352442f-5289-4ae4-80ce-6c52292b4397
html"""
<h2 style="text-align: center">Modelo de redes neuronales artificiales</h2>
"""

# ╔═╡ 33f103bd-d43b-4403-a1e7-ac963051a6c6
md"""
En este caso, asumimos que:

$$O(t) \approx a\frac{1}{1+e^{bt+c}} + d \frac{1}{1+e^{ft+g}}$$
"""

# ╔═╡ b367f966-0d54-4824-b38f-fe78fac70748
md"""
y queremos estimar los parámetros $a$, $b$, $c$, $d$, $f$ y $g$. Para esto, definimos una función para medir el desajuste del modelo utilizando mínimos cuadrados:
"""

# ╔═╡ 8217f156-4c1a-4a21-b7f7-46223b141649
function residuoMANN(par, O, t)
	a, b, c, d, f, g = par
	one = fill(1, length(t))
	Opred = a*( one./ (one+exp.(b*t+c*one)  ))+d*( one./ (one+exp.(f*t+g*one)  ))
	nres = norm(O - Opred)
	return nres
end

# ╔═╡ 6ab51698-dfa2-48f2-b303-67cef7437585
md"""
Ahora declaramos la función a optimizar:
"""

# ╔═╡ 9bbbbd33-8405-4661-be46-e6efa8d47e3b
rMANN(par) = residuoMANN(par, values, tiempo)

# ╔═╡ d8e79b95-4920-4f68-bf77-8f4405110ae7
md"""
y la optimizamos:
"""

# ╔═╡ 2b96a551-eb7f-4a7e-a4d7-6d033640bd88
oANN = Optim.optimize(rMANN, [0.01,.0001,.001,0.01,.0001,.001], BFGS())

# ╔═╡ 1e2f1cc0-c886-4971-843d-b2620cce5ca3
md"""
Obtenemos los siguientes valores óptimos:
"""

# ╔═╡ 3ac314c7-8e05-4f96-ace0-0eae06b4940d
resANN = oANN.minimizer

# ╔═╡ 291f0f6b-119e-401c-8cbf-238dcfd87f2e
md"""
Y el siguiente valor mínimo:
"""

# ╔═╡ 1d648ed3-1f29-4908-ae2a-b1b9daf150bd
oANN.minimum

# ╔═╡ b1bb8b57-4281-46aa-bd5a-51b737115d34
md"""
Llegando al siguiente modelo:

$$O(t) \approx 145.32\frac{1}{1+e^{-0.454165t+
8.30715}} + 335.343 \frac{1}{1+e^{-0.190257t-0.257313}}$$
"""

# ╔═╡ c9824e17-8438-4d11-9a8b-e1334a205062
begin
	oneaux = fill(1, length(values))
	plot(tiempo, values, seriestype=:scatter, ylabel="Cantidad", xlabel="Tiempo", legend=true, title="Ocupación de Camas UCI Covid-19 - Modelo ANN", size=(600, 400), color=:red, label="Ocupación")
	plot!(tiempo, [resANN[1] .* (oneaux ./ (oneaux .+ exp.(resANN[2].*tiempo .+ resANN[3] .* oneaux))) .+ resANN[4] .* (oneaux ./ (oneaux .+ exp.(resANN[5].*tiempo .+ resANN[6] .* oneaux)))], color=:blue, linewidth=3, label="Modelo ANN")
end

# ╔═╡ 552d16a6-6bed-4487-86d3-8d67754e91b6
html"""
<h2 style="text-align:center">Modelos sugeridos</h2?
"""

# ╔═╡ e6a10885-305c-4666-984c-294cc36e44e9
html"""
<h3 style="text-align:center">Modelo racional </h3>
"""

# ╔═╡ a453b406-4daf-429b-9cf2-66ddcc2f46d9
md"""
Ahora, probemos con el modelo:

$$O(t)\approx A \frac{1}{t} + B$$

"""

# ╔═╡ 99c643d8-4077-4cfb-ba3e-aeba29119238
md"""
De nuevo, queremos hallar la optimización para los parametros A y B que nos den el mínimo error. En primer lugar, definimos la función que nos de el desajuste del modelo usando mínimos cuadrados
"""

# ╔═╡ 19b541cb-9840-4bac-b411-974f2a77bd10
function residuoRAC(par, O, t)
	A,B = par
	one = fill(1, length(t))
	Opred = A ./ t + B*one
	nres = norm(O - Opred)
	return nres
end

# ╔═╡ 4abcf1fc-44e4-4ae9-8a4a-b62f841dbe19
md"""
Veamos como se comporta este modelo con diferentes valores de los parametros A y B
"""

# ╔═╡ b93cd336-6967-442b-aa25-e079140e19f5
begin
	aMRAC = @bind aMRacv Slider(-500:.1:500, show_value=true, default=199.068)
	bMRAC = @bind bMRacv Slider(-500:.1:500, show_value=true, default=10.6459)
	resMRacv = residuoRAC([aMRacv, bMRacv], values, tiempo)
end;

# ╔═╡ 15834063-da8b-4739-b617-fa014b7511b5
md"""
a = $aMRAC

b = $bMRAC

residuo = $resMRacv
"""

# ╔═╡ 410c2bfd-27e0-4ad7-8c7d-639e96d561cd
begin
	plot(tiempo, values, seriestype=:scatter, ylabel="Cantidad", xlabel="Tiempo", legend=true, title="Ocupación de Camas UCI Covid-19 - Modelo Racional", size=(600, 400), color=:red, label="Ocupación")
	plot!(tiempo, [aMRacv./tiempo.+bMRacv], color=:blue, linewidth=3, 
		 
		label="Modelo Racional")
end

# ╔═╡ 253df189-1341-4928-8dc6-81c6091d9e76
md"""
Ahora, a partir de la función de residuos, creamos una nueva función que depende solo de los parámetros. Es esta función la que optimizaremos
"""

# ╔═╡ c6d9fbfa-5234-4515-ba81-631d5ebf8154
rMRacional(par) = residuoRAC(par, values, tiempo)

# ╔═╡ aa741fce-7971-4251-8c25-a33a1906d197
md"""
Posteriormente realizamos la optimización. Para seleccionar los valores iniciales nos apoyamos de la exploración inicial realizada en el gráfico anterior

"""

# ╔═╡ ed139a17-1b1b-436d-8fa2-3b68d596b6c0
oRacional = Optim.optimize(rMRacional, [-371.9, 328.8], LBFGS())

# ╔═╡ 7e673373-0c1e-4e42-8409-0b86ec437dd6
md"""
Obtenemos los parametros óptimos
"""

# ╔═╡ e508e8e7-7479-4d44-a508-a50fcf8891e6
racMin = oRacional.minimizer

# ╔═╡ dda359c4-3289-4ff1-a406-7ff1581015e9
md"""
Y el desajuste mínimo encontrado
"""

# ╔═╡ 3df22914-0f7d-4eef-944e-a00f7f56bd4c
oRacional.minimum

# ╔═╡ fd2067f4-7679-4a3d-9b64-23811930b4f9
md"""
Veamos como se ve el ajuste de este modelo usando los parametros óptimos

"""

# ╔═╡ e2375f9a-0d6a-404b-8037-21f022963460
begin
	plot(tiempo, values, seriestype=:scatter, ylabel="Cantidad", xlabel="Tiempo", legend=true, title="Ocupación de Camas UCI Covid-19 - Modelo Racional", size=(600, 400), color=:red, label="Ocupación")
	plot!(tiempo, [racMin[1]./tiempo.+racMin[2]], color=:blue, linewidth=3, 
		 
		label="Modelo Racional")
end

# ╔═╡ 241505fe-9d9a-410b-be23-fe8d58a6ec58
md"""
Como vemos, el ajuste no es muy acertado. Por tanto, procedemos a implementar un modelo un poco más complejo:

$$O(t)\approx \frac{t}{At+ B}$$

"""

# ╔═╡ 2b096a03-1748-4455-8a3c-a063a29ffda1
md"""
Definimos la función que nos calcule el desajuste usando mínimos cuadrados:

"""

# ╔═╡ 3bdcdb42-af44-4ce0-82a6-a2274c4f338a
function residuoRAC2(par, O, t)
	A,B = par
	one = fill(1, length(t))
	Opred = t ./ (A.*t + B*one)
	nres = norm(O - Opred)
	return nres
end

# ╔═╡ 9ad97f28-0d39-4583-8015-2e9fec9b00f4
md"""
De nuevo, es útil observar el comportamiento de este modelo para distintos valores de nuestros parámetros:

"""

# ╔═╡ 71d61e53-d360-4792-bf2b-1c02780d9955
begin
	aMRAC2 = @bind aMRacv2 Slider(-1:.0001:1, show_value=true, default=199.068)
	bMRAC2 = @bind bMRacv2 Slider(-1:.0001:1, show_value=true, default=10.6459)
	resMRacv2 = residuoRAC2([aMRacv2, bMRacv2], values, tiempo)
end;

# ╔═╡ f2722416-6db5-4ddc-8310-768d2549c73c
md"""
a = $aMRAC2

b = $bMRAC2

residuo = $resMRacv2
"""

# ╔═╡ cdd1ad99-80b7-4e19-a9d5-9d7b0d6f2f7e
begin
	plot(tiempo, values, seriestype=:scatter, ylabel="Cantidad", xlabel="Tiempo", legend=true, title="Ocupación de Camas UCI Covid-19 - Modelo Racional 2", size=(900,600), color=:red, label="Ocupación")
	plot!(tiempo, tiempo./(aMRacv2.*tiempo.+bMRacv2), color=:blue, linewidth=3, 
		 
		label="Modelo Racional")
end

# ╔═╡ 641ca24d-a1a8-4538-aa3c-b6f2f58494a6
md"""
La razón por la que los valores elegibles de los parámeetros en el slider son tan pequeños es sencilla. Para valores grandes de A y B el modelo tiende a cero. Puesto que si $$At + B > t$$ entonces $$\frac{t}{At+ B} < 1$$.

Por tanto, para evitar lo anterior, los valores de A y B son cercanos a cero

"""

# ╔═╡ 180cbe4a-fd61-4c90-883d-f83b79103ec6
md"""
A continuación creamos una función que depende únicamente de los parametros. Esta función será la cual usaremos para minimizar los valores de A y B

"""

# ╔═╡ fa91bc13-cbbf-44db-91bf-0555ed0376b4
rMRacional2(par) = residuoRAC2(par, values, tiempo)

# ╔═╡ 572c5522-d4fe-42da-841a-449566099d04
md"""
Dada la explicación anteriormente, le damos valores iniciales cercanos a cero a los parámetros

"""

# ╔═╡ 54eb8804-4887-4a58-bd9b-fcd9d5a4a633
oRacional2 = Optim.optimize(rMRacional2, [0.01, 0.003], LBFGS())

# ╔═╡ cf2d64bd-f191-488e-a13f-7be6bcaf729e
racMin2 = oRacional2.minimizer

# ╔═╡ f083b4e0-3371-48ed-8e21-bfc7dfc23a6b
md"""
Una vez que obtenemos los valores óptimos para los parámetros, graficamos la curva con estos 

"""

# ╔═╡ 2190eef8-254d-440e-9728-042c09f71575
oRacional2.minimum

# ╔═╡ 3ec46373-2fdd-4bd1-8c97-7dba659cb773
begin
	plot(tiempo, values, seriestype=:scatter, ylabel="Cantidad", xlabel="Tiempo", legend=true, title="Ocupación de Camas UCI Covid-19 - Modelo Racional", size=(600, 400), color=:red, label="Ocupación")
	plot!(tiempo, [ tiempo./(racMin2[1].*tiempo.+racMin2[2])], color=:blue, linewidth=3, 
		 
		label="Modelo Racional")
end

# ╔═╡ 6b73f861-974b-4191-83fa-fcb05cc99a55
html"""
<h2 style="text-align:center">Modelos de ecuaciones diferenciales</h2>
"""

# ╔═╡ fd33b892-a02f-4a42-95e3-e53ea233fb89
html"""
<h3 style="text-align:center">Modelo SIR (Susceptible-Infectious-Recovered)</h3>
"""

# ╔═╡ 7e0800a1-fdd7-4140-ab8f-bf6677d0a271
md"""
Probaremos el modelo SIR [4], el cual divide a la población en tres grupos: susceptibles, infectados y recuperados. Las ecuaciones asociadas son:

$$\frac{dS}{dt} = -\beta \frac{S\cdot I}{N}$$

$$\frac{dI}{dt} = \beta \frac{S\cdot I}{N}-\gamma I$$

$$\frac{dR}{dt} = \gamma I$$

donde $S$ representa las personas que pueden contraer la infección, I las personas actualmente infectadas, R las personas que ya no son susceptibles y $N=S+I+R$. En cuanto a los parámetros, $\beta$ representa la tasa de infección y $\gamma$ la de recuperación.

El nivel de ocupación de camas UCI estará asociado a la proporción de infectados que requiere ser hospitalizada, esto es $h\cdot I$ para $h\in (0, 1)$.
"""

# ╔═╡ 17d50742-8407-4d3a-a491-3cbd8deea720
md"""
Queremos encontrar los parámetros $\beta$, $\gamma$ y $h$ más óptimos.
"""

# ╔═╡ 7640a3e8-b0ee-46e8-af45-757228604036
md"""
En primer lugar, definimos el modelo:
"""

# ╔═╡ 3cc80e2c-49af-4d63-90aa-d86b91bcce6e
function modeloEDO(du, u, par, t)
  S, I, R = u
  beta, gamma = par
  N = S + I + R

  du[1] = -(beta*S*I)/N          
  du[2] = (beta*S*I)/N - gamma*I    
  du[3] = gamma*I                      
end

# ╔═╡ e3a60f67-2035-4ba2-acbd-3befb4b5101f
md"""
A continuación, implementamos una función para medir el error de ajuste:
"""

# ╔═╡ 95301630-fbe5-47df-a69c-b45d1c61e80a
function residuoMEDO(par, O, tiempo)
  beta, gamma, h = par
	
  S0 = 8000000.0 
  I0 = values[1] / h  
  R0 = 0.0
	
  u0 = [S0, I0, R0]
  tspan = (tiempo[1], tiempo[end])
	
  EDO = ODEProblem(modeloEDO, u0, tspan, [beta, gamma])
  OSol = solve(EDO)
	
  O_model = [h * OSol(t)[2] for t in tiempo]
  res = O - O_model
  nres = norm(res)
  return nres
end

# ╔═╡ 309411fa-35eb-4a80-b244-e06a8e74d472
md"""
Nota: $S_0$ es una estimación de la población de Bogotá; estimaremos $I_0$ con base en los datos que tenemos y el parámetro $h$; asumimos que el número de personas recuperadas en el tiempo $1$ es $0$.
"""

# ╔═╡ 8902ec37-4fbc-4a94-b09b-da93227116b5
md"""
Declaramos la función a minimizar:
"""

# ╔═╡ 9723dd49-4df8-4a50-92fd-c1ef0f46cc09
rEDO(par) = residuoMEDO(par, values, tiempo)

# ╔═╡ d497944c-589d-46c4-8ffd-ec48234da8f7
md"""
Y la optimizamos:
"""

# ╔═╡ ce61bf03-9a5a-480e-a9ea-352cdda83d94
oEDO = Optim.optimize(rEDO, [0.1, 0.1, 0.1], NelderMead())

# ╔═╡ e06e972c-1f19-4759-9776-d57cb99ff864
md"""
Obteniendo los siguientes valores para $\beta$, $\gamma$ y $h$, respectivamente:
"""

# ╔═╡ 74696ca3-8f3e-4129-9900-f4b38dc78309
resEDO = oEDO.minimizer

# ╔═╡ 8c443adb-692b-4b55-9e6a-577817bbcda9
md"""
Y teniendo el siguiente valor mínimo:
"""

# ╔═╡ 52ded531-752b-4427-bdfe-6a414d2bd426
oEDO.minimum

# ╔═╡ 1ceb7ca2-bb9a-4b70-b6ee-d6ec174c7b29
md"""
Visualicémolo con estos parámetros:
"""

# ╔═╡ 765e89bd-8c45-4c7c-80c3-c6a36c5fcf85
begin
	plot(tiempo, values, seriestype=:scatter, ylabel="Cantidad", xlabel="Tiempo", legend=true, title="Ocupación de Camas UCI Covid-19 - Modelo SIR", size=(600, 400), color=:red, label="Ocupación")

	beta, gamma, h = resEDO
  	S0 = 8000000.0 
  	I0 = values[1] / h 
  	R0 = 0.0
  	u0 = [S0, I0, R0]
  	tspan = (tiempo[1], tiempo[end])
  	EDO = ODEProblem(modeloEDO, u0, tspan, [beta, gamma])
  	OSol = solve(EDO)
  	I_model = [h * OSol(t)[2] for t in tiempo]
	
	plot!(tiempo,  I_model, color=:blue, linewidth=3, label="Modelo SIR")
end

# ╔═╡ f143162c-f3e8-4450-b9fb-9768284bf7cb
md"""
Adicionalmente, podemos ver cómo se comporta este modelo con ejemplos que no incluimos en el conjunto de datos inicial:
"""

# ╔═╡ 782b3bf5-54a8-4909-af98-2e344442a59f
tiempos_next = [i for i in range(20, 35)]

# ╔═╡ 316413eb-4f9a-4c8f-99d1-b2d55ddc6720
values_next = [431, 452, 467, 488, 525, 602, 581, 608, 599, 612, 618, 631, 649, 626, 651, 653]

# ╔═╡ d5b2a7de-535b-41fd-a5d9-b9fb939f4eeb
begin
	plot(vcat(tiempo, tiempos_next), vcat(values, values_next), seriestype=:scatter, ylabel="Cantidad", xlabel="Tiempo", legend=true, title="Ocupación de Camas UCI Covid-19 - Modelo SIR", size=(600, 400), color=:red, label="Ocupación")
	plot!(tiempo,  I_model, color=:blue, linewidth=3, label="Modelo SIR")
	plot!(tiempos_next,  [h*OSol(t)[2] for t in tiempos_next], color=:orange, linewidth=3, label="Modelo SIR - Predicción")
end

# ╔═╡ e3cba55b-1801-4437-a045-fb71da811d6c
html"""
<h3 style="text-align:center"> Modelo SEIR con Hospitalización y UCI</h3>
"""

# ╔═╡ 1f1852ac-b1b9-4f00-9b41-3c398bf2eda6
md"""
Este modelo es una extensión del SEIR (Susceptible-Exposed-Infectious-Recovered) que introduce un subgrupo de los infectados que requiere hospitalización ($H$) y otro que requiere atención en UCI ($C$); es una simplificación del modelo presentado en [5]. Consiste de las siguientes ecuaciones:

$$\frac{dS}{dt}=-\beta \frac{S\cdot I}{N}$$

$$\frac{dE}{dt}= \beta \frac{S\cdot I}{N} - \sigma E$$

$$\frac{dI}{dt} = \sigma E - \gamma I - \delta H - \eta C$$

$$\frac{dH}{dt} = \delta I - \alpha H$$

$$\frac{dC}{dt} = \eta I - \lambda C$$

$$\frac{dR}{dt} = \gamma I + \alpha H + \lambda C$$
"""

# ╔═╡ d5765d9c-011f-4f84-8f36-56e9ec6ed1b1
md"""
donde $S$ representa las personas susceptibles a enfermarse, $E$ las personas expuesstas a la enfermedad, $I$ las personas infectadas, $H$ representa las personas en hospitalización normal, $C$ las personas en camas UCI y $R$ las personas recuperadas. La población total es $N = S+E+I+H+C+R$.

En cuanto a los parámetros, $\beta$ es la tasa de infección, $\sigma$ la tasa de velocidad a la que las personas expuestas se vuelven infecciosas, $\gamma$ la tasa de recuperación, $\delta$ la tasa de ingreso hospitalario, $\eta$ la tasa de ingreso a UCI, $\alpha$ la tasa de alta de hospitalización y $\lambda$ la tasa de alta de UCI.
"""

# ╔═╡ 1e599ef8-9cc3-4d7b-a5bd-113394dc188e
md"""
Queremos estimar los parámetros $\beta$, $\sigma$, $\gamma$, $\delta$, $\eta$, $\alpha$, $\lambda$ para obtener una buena aproximación de la variable $C$ (la ocupación de camas UCI), para ello definimos el modelo:
"""

# ╔═╡ 5f50413c-1932-4b11-aa1b-feaa3337d9fb
function modeloEDO2(du, u, par, t)
	S, E, I, H, C, R = u
	beta, sigma, gamma, delta, eta, alpha, lambda = par
	N = S + E + I + H + C + R
	
	du[1] = -beta*S*I/N
	du[2] = beta*S*I/N - sigma*E
	du[3] = sigma*E - gamma*I - delta*H - eta*C
	du[4] = delta*I - alpha*H
	du[5] = eta*I - lambda*C
	du[6] = gamma*I + alpha*H + lambda*C
end

# ╔═╡ 333e4d90-1f58-41a3-b8d7-a694740ae138
md"""
A continuación, implementamos una función para medir el desajuste del modelo. Utilizaremos los parámetros $h_1$ y $h_2$ para estimar el número de personas expuestas al virus en el tiempo $1$ y el número de personas hospitalizadas en el tiempo $1$, respectivamente.
"""

# ╔═╡ 75b98e62-8a3e-43aa-8387-24389ef91428
function residuoMEDO2(par, values, tiempo)
	beta, sigma, gamma, delta, eta, alpha, lambda, h1, h2 = par

	S0 = 8000000.0
	E0 = S0 * h1
	I0 = 1500000.0
	H0 = I0 * h2
	C0 = values[1]
	R0 = 0.0

	u0 = [S0, E0, I0, H0, C0, R0]
	tspan = (tiempo[1], tiempo[end])

	EDO = ODEProblem(modeloEDO2, u0, tspan, [beta, sigma, gamma, delta, eta, alpha, lambda])
	Osol = solve(EDO)

	O_model = [Osol(t)[5] for t in tiempo]
	res = values - O_model
	
	return norm(res)
end

# ╔═╡ 5a9d494e-bfae-4398-97ce-7fa5dc48b609
md"""
Nota: Tomamos $S_0$ como una estimación de la población de Bogotá e $I_0$ con base en [3].
"""

# ╔═╡ 53ee3204-fcac-44e4-874d-eccc2f2f1d23
md"""
Declaramos la función a optimizar:
"""

# ╔═╡ 7d0f940c-fc0c-4e4f-8764-5bee609f1989
rEDO2(par) = residuoMEDO2(par, values, tiempo)

# ╔═╡ b44da75e-9371-4ca9-a2d7-2c43954ae359
md"""
y la optimizamos:
"""

# ╔═╡ 4725eb44-79e8-4d0d-b1b3-d4b8de23e9bb
oEDO2 = Optim.optimize(rEDO2, [0.1, 0.5, 0.01, 0.3, 0.1, 0.4, 0.01, 0.5, 0.5], NelderMead())

# ╔═╡ dccdea07-f998-49b3-93ee-41216913d527
md"""
Nota: Probando con distintos valores iniciales para los parámetros, el residuo puede cambiar drásticamente.
"""

# ╔═╡ 955fb2dc-b11a-4f97-a841-f84aa45a7e0c
md"""
Obteniendo los siguientes valores óptimos:
"""

# ╔═╡ 16711214-f8e6-4b29-99d2-c01fd5cead92
resEDO2 = oEDO2.minimizer

# ╔═╡ 42d4af87-6a18-4a2a-8192-07fb221a03c9
md"""
y el siguiente valor mínimo:
"""

# ╔═╡ d258b346-169b-48d4-a2bb-f1219b211aa1
oEDO2.minimum

# ╔═╡ c447e9a0-cf40-4a55-9513-e68faeb86d8a
md"""
Podemos visualizarlo:
"""

# ╔═╡ 7d9a476b-2201-42be-92f4-3cc0deb03538
begin
	plot(tiempo, values, seriestype=:scatter, ylabel="Cantidad", xlabel="Tiempo", legend=true, title="Ocupación de Camas UCI Covid-19 - Modelo SEIR", size=(600, 400), color=:red, label="Ocupación")

	beta1, sigma1, gamma1, delta1, eta1, alpha1, lambda1, h1, h2 = resEDO2
	tspan1 = (1, 25)
  	u01 = [8000000.0, 8000000.0 * h1, 1500000.0, 1500000.0 * h2, values[1], 0.0]
  	EDO2 = ODEProblem(modeloEDO2, u01, tspan1, [beta1, sigma1, gamma1, delta1, eta1, alpha1, lambda1])
	Osol1 = solve(EDO2)

	O_model1 = [Osol1(t)[5] for t in tiempo]
	
	plot!(tiempo,  O_model1, color=:blue, linewidth=3, label="Modelo SEIR")
end

# ╔═╡ 984c358e-ec73-4f32-ae42-94b82b338029
md"""
Podemos ver cómo se comporta este modelo con ejemplos que no incluimos en el conjunto de datos inicial:
"""

# ╔═╡ 09646d1c-49ed-44ed-be41-108ae0c2634b
begin
	plot(vcat(tiempo, tiempos_next), vcat(values, values_next), seriestype=:scatter, ylabel="Cantidad", xlabel="Tiempo", legend=true, title="Ocupación de Camas UCI Covid-19 - Modelo SEIR", size=(600, 400), color=:red, label="Ocupación")
	plot!(tiempo,  O_model1, color=:blue, linewidth=3, label="Modelo SEIR")
	plot!(tiempos_next,  [Osol1(t)[5] for t in tiempos_next], color=:orange, linewidth=3, label="Modelo SEIR - Predicción")
end


# ╔═╡ fb43a7a0-b3ec-4787-b464-2a18b2386cb7
html"""
<h2 style="text-align:center">Conclusiones</h2>
"""

# ╔═╡ bbf93e76-ede2-4847-9cf6-7872c3239784
md"""
- Los modelos que mejor comportamiento tienen son aquellos con mayor cantidad de parámetros. No obstante, tal como lo probamos para el modelo SEIR, estos modelos pierden de su capacidad predictiva debido a *sobreajuste*

- En general, los modelos de ecuaciones resultaron tener un mejor desempeño y ser más interpretables.  Pues aunque modelos como el polinomio cúbico y de redes neuronales también tuvieron buenos desempeños, el valor de sus parámetros no es interpretable
"""
# ╔═╡ 1b77e663-3320-44b9-b50a-925be8482101
md"""
##    ----------------------------  Modelo $$\frac{D}{t+C}$$ -------------------------------
"""

# ╔═╡ f26d91ab-69a8-4dd7-b082-e3913fb1b1ce
function residuoM1(par, O, t)
    D, C = par
    oneaux = fill(1, length(t))
    Opred = D ./ (t .+ C)
    nres = norm(O - Opred)  # Calcula la norma de la diferencia
    return nres
end

# ╔═╡ 552bd461-e2e3-4fcb-b979-abb6c27328f6
rM1(par) = residuoM1(par, values, tiempo)

# ╔═╡ d5a3d006-1038-4154-b904-45e50a3e55bb


# ╔═╡ 93f4d25b-80fd-4a3a-b446-745ac1fcab73
o1 = optimize(rM1, [1.0,1.0], NelderMead())

# ╔═╡ d3045ada-9eea-48d7-a65f-33cd29f6380b
D_opt, C_opt = Optim.minimizer(o1)

# ╔═╡ bff408b6-cd10-48d5-b162-644fefda90c8
o1.minimum

# ╔═╡ c427d044-e40e-4923-a31e-299e80535a9b
begin
# Modelo ajustado
O_model2 = D_opt ./ (tiempo .+ C_opt)

# Predicción futura
O_pred_next = D_opt ./ (tiempos_next .+ C_opt)

# Crear el gráfico
scatter(
    tiempo, values, 
    ylabel="Valores Observados", 
    xlabel="Tiempo", 
    legend=true, 
    title="Ajuste del Modelo con residuoM2", 
    size=(600, 400), 
    color=:red, 
    label="Datos Reales"
)
plot!(
    tiempo, O_model2, 
    color=:blue, 
    linewidth=3, 
    label="Modelo Ajustado"
)

end

# ╔═╡ 26c649f1-6670-44a3-883c-865c869322a8


# ╔═╡ e590b0ac-5e8c-4b26-bc4b-d576b372d721
function residuoM4(par, O, t)
    C, A = par
    Opred = C .* exp.(A .* t)  # Predicción basada en el modelo C * e^(A * t)
    nres = norm(O - Opred)     # Norm de la diferencia (residuo)
    return nres
end

# ╔═╡ 5efc73e2-12d9-43c7-a577-a59667f7044c
rM4(par) = residuoM4(par, values, tiempo)

# ╔═╡ 833616e1-55bf-4719-aac0-8bbeaa88d9c2
o4 = optimize(rM4, [11.0,12.0], NelderMead())

# ╔═╡ 8126ed19-fd04-4787-8608-d23ba8236f26
C2_opt, A_opt = o4.minimizer

# ╔═╡ f097690d-9d60-415f-9150-de23e9e2eea3
o4.minimum

# ╔═╡ ec477bb8-41dd-4c38-bf84-bdac076fbee1
Opred = C2_opt .* exp.(A_opt .* tiempo)

# ╔═╡ 31a86d14-c9da-4cb0-80bd-eddfd22cef60
Opred_next =  C2_opt .* exp.(A_opt .* tiempos_next)

# ╔═╡ 765ebfcb-710d-4198-b9c4-bb603141a901
# Graficar los resultados
begin
plot(tiempo, values, seriestype=:scatter, xlabel="Tiempo", ylabel="Cantidad", label="Datos Observados", title="Ajuste del modelo C * e^(A * t)", size=(600, 400), color=:red)
plot!(tiempo, Opred, label="Modelo Ajustado", linewidth=3, color=:blue)
end

# ╔═╡ 77342518-bfbc-4531-9993-9f64a0552b35
begin
	plot(vcat(tiempo, tiempos_next), vcat(values, values_next), seriestype=:scatter, ylabel="Cantidad", xlabel="Tiempo", legend=true, title="Ocupación de Camas UCI Covid-19 - Modelo SEIR", size=(600, 400), color=:red, label="Ocupación")
	plot!(tiempo,  Opred, color=:blue, linewidth=3, label="Modelo SEIR")
	plot!(tiempos_next,  Opred_next, color=:orange, linewidth=3, label="Modelo SEIR - Predicción")
end


# ╔═╡ 34506416-a59a-450f-835b-72f0fbc6ce74
html"""
<h2 style="text-align:center">Referencias</h2>
"""

# ╔═╡ 62e65843-4d73-4a18-8c7d-707b1e66a2d4
md"""
1. Ajuste de curvas. Laboratorio De Matemáticas. [https://labmatecc.github.io/Notebooks/AnalisisNumerico/AjusteDeCurvas/](https://labmatecc.github.io/Notebooks/AnalisisNumerico/AjusteDeCurvas/)


2. Datos abiertos Bogotá. (n.d.). [https://datosabiertos.bogota.gov.co/dataset/ocupacion-de-camas-uci-covid-19-bogota-d-c](https://datosabiertos.bogota.gov.co/dataset/ocupacion-de-camas-uci-covid-19-bogota-d-c)


3. Becerra, B. X. (2022, Enero 1). Colombia inicia 2022 con más de 12.000 contagios por covid-19 y con 44 fallecidos. Diario La República. [https://www.larepublica.co/economia/casos-de-covid-hoy-1-de-enero-en-colombia-3282789](https://www.larepublica.co/economia/casos-de-covid-hoy-1-de-enero-en-colombia-3282789)


4. RPUBS - Modelo SIR - ODE - I. (n.d.). [https://rpubs.com/dsfernandez/675857](https://rpubs.com/dsfernandez/675857)


5. Delli Compagni R, Cheng Z, Russo S, Van Boeckel TP. A hybrid Neural Network-SEIR model for forecasting intensive care occupancy in Switzerland during COVID-19 epidemics. PLoS One. 2022 Mar 3;17(3):e0263789. doi: 10.1371/journal.pone.0263789. PMID: 35239662; PMCID: PMC8893679.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
DifferentialEquations = "0c46a032-eb83-5123-abaf-570d42b7fbaa"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Optim = "429524aa-4258-5aef-a3af-852621145aeb"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[compat]
DifferentialEquations = "~7.13.0"
Optim = "~1.10.0"
Plots = "~1.40.9"
PlutoUI = "~0.7.60"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.3"
manifest_format = "2.0"
project_hash = "8ea8239a3d54efbe75d3a5a01830c3514789e9a6"

[[deps.ADTypes]]
git-tree-sha1 = "016833eb52ba2d6bea9fcb50ca295980e728ee24"
uuid = "47edcb42-4c32-4615-8424-f2b9edc5f35b"
version = "0.2.7"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "cde29ddf7e5726c9fb511f340244ea3481267608"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.7.2"
weakdeps = ["StaticArrays"]

    [deps.Adapt.extensions]
    AdaptStaticArraysExt = "StaticArrays"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "d57bd3762d308bded22c3b82d033bff85f6195c6"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.4.0"

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra", "Requires", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "c5aeb516a84459e0318a02507d2261edad97eb75"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.7.1"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.ArrayLayouts]]
deps = ["FillArrays", "LinearAlgebra"]
git-tree-sha1 = "492681bc44fac86804706ddb37da10880a2bd528"
uuid = "4c555306-a7a7-4459-81d9-ec55ddd5c99a"
version = "1.10.4"
weakdeps = ["SparseArrays"]

    [deps.ArrayLayouts.extensions]
    ArrayLayoutsSparseArraysExt = "SparseArrays"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.BandedMatrices]]
deps = ["ArrayLayouts", "FillArrays", "LinearAlgebra", "PrecompileTools"]
git-tree-sha1 = "a2c85f53ddcb15b4099da59867868bd40f005579"
uuid = "aae01518-5342-5314-be14-df237901396f"
version = "1.7.5"
weakdeps = ["SparseArrays"]

    [deps.BandedMatrices.extensions]
    BandedMatricesSparseArraysExt = "SparseArrays"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitFlags]]
git-tree-sha1 = "0691e34b3bb8be9307330f88d1a3c3f25466c24d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.9"

[[deps.BitTwiddlingConvenienceFunctions]]
deps = ["Static"]
git-tree-sha1 = "f21cfd4950cb9f0587d5067e69405ad2acd27b87"
uuid = "62783981-4cbd-42fc-bca8-16325de8dc4b"
version = "0.1.6"

[[deps.BoundaryValueDiffEq]]
deps = ["ADTypes", "Adapt", "ArrayInterface", "BandedMatrices", "ConcreteStructs", "DiffEqBase", "FastAlmostBandedMatrices", "ForwardDiff", "LinearAlgebra", "LinearSolve", "NonlinearSolve", "PreallocationTools", "PrecompileTools", "Preferences", "RecursiveArrayTools", "Reexport", "SciMLBase", "Setfield", "SparseArrays", "SparseDiffTools", "Tricks", "TruncatedStacktraces", "UnPack"]
git-tree-sha1 = "3ff968887be48760b0e9e8650c2d05c96cdea9d8"
uuid = "764a87c0-6b3e-53db-9096-fe964310641d"
version = "5.6.3"

    [deps.BoundaryValueDiffEq.extensions]
    BoundaryValueDiffEqODEInterfaceExt = "ODEInterface"
    BoundaryValueDiffEqOrdinaryDiffEqExt = "OrdinaryDiffEq"

    [deps.BoundaryValueDiffEq.weakdeps]
    ODEInterface = "54ca160b-1b9f-5127-a996-1867f4bc2a2c"


[[deps.BoundaryValueDiffEqCore]]
deps = ["ADTypes", "Adapt", "ArrayInterface", "ConcreteStructs", "DiffEqBase", "ForwardDiff", "LineSearch", "LineSearches", "LinearAlgebra", "LinearSolve", "Logging", "NonlinearSolve", "PreallocationTools", "RecursiveArrayTools", "Reexport", "SciMLBase", "Setfield", "SparseArrays", "SparseDiffTools"]
git-tree-sha1 = "b4556571d1e80faa5f62ac8732a07bae0ee24dc6"
uuid = "56b672f2-a5fe-4263-ab2d-da677488eb3a"
version = "1.0.2"

[[deps.BoundaryValueDiffEqFIRK]]
deps = ["ADTypes", "Adapt", "ArrayInterface", "BandedMatrices", "BoundaryValueDiffEqCore", "ConcreteStructs", "DiffEqBase", "FastAlmostBandedMatrices", "FastClosures", "ForwardDiff", "LineSearch", "LineSearches", "LinearAlgebra", "LinearSolve", "Logging", "NonlinearSolve", "PreallocationTools", "PrecompileTools", "Preferences", "RecursiveArrayTools", "Reexport", "SciMLBase", "Setfield", "SparseArrays", "SparseDiffTools"]
git-tree-sha1 = "35e1e7822d1c77d85ecf568606ca64d60fbd39de"
uuid = "85d9eb09-370e-4000-bb32-543851f73618"
version = "1.0.2"

[[deps.BoundaryValueDiffEqMIRK]]
deps = ["ADTypes", "Adapt", "ArrayInterface", "BandedMatrices", "BoundaryValueDiffEqCore", "ConcreteStructs", "DiffEqBase", "FastAlmostBandedMatrices", "FastClosures", "ForwardDiff", "LineSearch", "LineSearches", "LinearAlgebra", "LinearSolve", "Logging", "NonlinearSolve", "PreallocationTools", "PrecompileTools", "Preferences", "RecursiveArrayTools", "Reexport", "SciMLBase", "Setfield", "SparseArrays", "SparseDiffTools"]
git-tree-sha1 = "e1fa0dee3d8eca528ab96e765a52760fd7466ffa"
uuid = "1a22d4ce-7765-49ea-b6f2-13c8438986a6"
version = "1.0.1"

[[deps.BoundaryValueDiffEqShooting]]
deps = ["ADTypes", "Adapt", "ArrayInterface", "BandedMatrices", "BoundaryValueDiffEqCore", "ConcreteStructs", "DiffEqBase", "FastAlmostBandedMatrices", "FastClosures", "ForwardDiff", "LineSearch", "LineSearches", "LinearAlgebra", "LinearSolve", "Logging", "NonlinearSolve", "OrdinaryDiffEq", "PreallocationTools", "PrecompileTools", "Preferences", "RecursiveArrayTools", "Reexport", "SciMLBase", "Setfield", "SparseArrays", "SparseDiffTools"]
git-tree-sha1 = "fac04445ab0fdfa29b62d84e1af6b21334753a94"
uuid = "ed55bfe0-3725-4db6-871e-a1dc9f42a757"
version = "1.0.2"

    OrdinaryDiffEq = "1dea7af3-3e70-54e6-95c3-0bf5283fa5ed"


[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "8873e196c2eb87962a2048b3b8e08946535864a1"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+2"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.CPUSummary]]
deps = ["CpuId", "IfElse", "PrecompileTools", "Static"]
git-tree-sha1 = "5a97e67919535d6841172016c9530fd69494e5ec"
uuid = "2a0fbf3d-bb9c-48f3-b0a9-814d99fd7ab9"
version = "0.2.6"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "009060c9a6168704143100f36ab08f06c2af4642"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.2+1"


[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "3e4b134270b372f2ed4d4d0e936aabaefc1802bc"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.25.0"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"


[[deps.CloseOpenIntervals]]
deps = ["Static", "StaticArrayInterface"]
git-tree-sha1 = "05ba0d07cd4fd8b7a39541e31a7b0254704ea581"
uuid = "fb6a15b2-703c-40df-9091-08a04967cfa9"
version = "0.1.13"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "bce6804e5e6044c6daab27bb533d1295e4a2e759"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.6"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "c785dfb1b3bfddd1da557e861b919819b82bbe5b"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.27.1"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "64e15186f0aa277e174aa81798f7eb8598e0157e"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.13.0"

[[deps.CommonSolve]]
git-tree-sha1 = "0eee5eb66b1cf62cd6ad1b460238e60e4b09400c"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.4"

[[deps.CommonSubexpressions]]
deps = ["MacroTools"]
git-tree-sha1 = "cda2cfaebb4be89c9084adaca7dd7333369715c5"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.1"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+0"

[[deps.ConcreteStructs]]
git-tree-sha1 = "f749037478283d372048690eb3b5f92a79432b34"
uuid = "2569d6c7-a4a2-43d3-a901-331e8e4be471"
version = "0.2.3"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "ea32b83ca4fefa1768dc84e504cc0a94fb1ab8d1"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.4.2"

[[deps.ConstructionBase]]
git-tree-sha1 = "76219f1ed5771adbb096743bff43fb5fdd4c1157"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.8"

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

    [deps.ConstructionBase.weakdeps]
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.Contour]]
git-tree-sha1 = "439e35b0b36e2e5881738abc8857bd92ad6ff9a8"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.3"

[[deps.CpuId]]
deps = ["Markdown"]
git-tree-sha1 = "fcbb72b032692610bfbdb15018ac16a36cf2e406"
uuid = "adafc99b-e345-5852-983c-f28acb93d879"
version = "0.3.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Dbus_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fc173b380865f70627d7dd1190dc2fce6cc105af"
uuid = "ee1fde0b-3d02-5ea6-8484-8dfef6360eab"
version = "1.14.10+0"

[[deps.DelayDiffEq]]
deps = ["ArrayInterface", "DataStructures", "DiffEqBase", "LinearAlgebra", "Logging", "OrdinaryDiffEq", "Printf", "RecursiveArrayTools", "Reexport", "SciMLBase", "SimpleNonlinearSolve", "SimpleUnPack"]
git-tree-sha1 = "dd3dfeca90deb4b38be9598d7c51cd558816e596"
uuid = "bcd4f6db-9728-5f36-b5f7-82caef46ccdb"
version = "5.45.1"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DiffEqBase]]
deps = ["ArrayInterface", "DataStructures", "DocStringExtensions", "EnumX", "EnzymeCore", "FastBroadcast", "ForwardDiff", "FunctionWrappers", "FunctionWrappersWrappers", "LinearAlgebra", "Logging", "Markdown", "MuladdMacro", "Parameters", "PreallocationTools", "PrecompileTools", "Printf", "RecursiveArrayTools", "Reexport", "SciMLBase", "SciMLOperators", "Setfield", "SparseArrays", "Static", "StaticArraysCore", "Statistics", "Tricks", "TruncatedStacktraces"]
git-tree-sha1 = "044648af911974c3928058c1f8c83f159dece274"
uuid = "2b5f629d-d688-5b77-993f-72d75c75574e"
version = "6.145.6"

    [deps.DiffEqBase.extensions]
    DiffEqBaseChainRulesCoreExt = "ChainRulesCore"
    DiffEqBaseDistributionsExt = "Distributions"
    DiffEqBaseEnzymeExt = ["ChainRulesCore", "Enzyme"]
    DiffEqBaseGeneralizedGeneratedExt = "GeneralizedGenerated"
    DiffEqBaseMPIExt = "MPI"
    DiffEqBaseMeasurementsExt = "Measurements"
    DiffEqBaseMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    DiffEqBaseReverseDiffExt = "ReverseDiff"
    DiffEqBaseTrackerExt = "Tracker"
    DiffEqBaseUnitfulExt = "Unitful"

    [deps.DiffEqBase.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    GeneralizedGenerated = "6b9d7cbe-bcb9-11e9-073f-15a7a543e2eb"
    MPI = "da04e1cc-30fd-572f-bb4f-1f8673147195"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.DiffEqCallbacks]]
deps = ["DataStructures", "DiffEqBase", "ForwardDiff", "Functors", "LinearAlgebra", "Markdown", "NLsolve", "Parameters", "RecipesBase", "RecursiveArrayTools", "SciMLBase", "StaticArraysCore"]
git-tree-sha1 = "cf334da651a6e42c50e1477d6ab978f1b8be3057"
uuid = "459566f4-90b8-5000-8ac3-15dfb0a30def"
version = "2.36.1"
weakdeps = ["OrdinaryDiffEq", "Sundials"]

[[deps.DiffEqNoiseProcess]]
deps = ["DiffEqBase", "Distributions", "GPUArraysCore", "LinearAlgebra", "Markdown", "Optim", "PoissonRandom", "QuadGK", "Random", "Random123", "RandomNumbers", "RecipesBase", "RecursiveArrayTools", "Requires", "ResettableStacks", "SciMLBase", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "ed0158e758723b4d429afbbb5d98c5afd3458dc1"
uuid = "77a26b50-5914-5dd7-bc55-306e6241c503"
version = "5.22.0"

    [deps.DiffEqNoiseProcess.extensions]
    DiffEqNoiseProcessReverseDiffExt = "ReverseDiff"

    [deps.DiffEqNoiseProcess.weakdeps]
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "23163d55f885173722d1e4cf0f6110cdbaf7e272"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.15.1"

[[deps.DifferentialEquations]]
deps = ["BoundaryValueDiffEq", "DelayDiffEq", "DiffEqBase", "DiffEqCallbacks", "DiffEqNoiseProcess", "JumpProcesses", "LinearAlgebra", "LinearSolve", "NonlinearSolve", "OrdinaryDiffEq", "Random", "RecursiveArrayTools", "Reexport", "SciMLBase", "SteadyStateDiffEq", "StochasticDiffEq", "Sundials"]
git-tree-sha1 = "81042254a307980b8ab5b67033aca26c2e157ebb"
uuid = "0c46a032-eb83-5123-abaf-570d42b7fbaa"
version = "7.13.0"

[[deps.Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "c7e3a542b999843086e2f29dac96a618c105be1d"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.12"

    [deps.Distances.extensions]
    DistancesChainRulesCoreExt = "ChainRulesCore"
    DistancesSparseArraysExt = "SparseArrays"

    [deps.Distances.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["AliasTables", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "3101c32aab536e7a27b1763c0797dba151b899ad"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.113"

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsTestExt = "Test"

    [deps.Distributions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DensityInterface = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EnumX]]
git-tree-sha1 = "bdb1942cd4c45e3c678fd11569d5cccd80976237"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.4"

[[deps.EnzymeCore]]
git-tree-sha1 = "1bc328eec34ffd80357f84a84bb30e4374e9bd60"
uuid = "f151be2c-9106-41f4-ab19-57ee4f262869"
version = "0.6.6"
weakdeps = ["Adapt"]

    [deps.EnzymeCore.extensions]
    AdaptExt = "Adapt"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8e9441ee83492030ace98f9789a654a6d0b1f643"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "d36f682e590a83d63d1c7dbd287573764682d12a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.11"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "cc5231d52eb1771251fbd37171dbc408bcc8a1b6"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.6.4+0"

[[deps.ExponentialUtilities]]
deps = ["Adapt", "ArrayInterface", "GPUArraysCore", "GenericSchur", "LinearAlgebra", "PrecompileTools", "Printf", "SparseArrays", "libblastrampoline_jll"]
git-tree-sha1 = "602e4585bcbd5a25bc06f514724593d13ff9e862"
uuid = "d4d017d3-3776-5f7e-afef-a10c40355c18"
version = "1.25.0"

[[deps.ExprTools]]
git-tree-sha1 = "27415f162e6028e81c72b82ef756bf321213b6ec"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.10"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "53ebe7511fa11d33bec688a9178fac4e49eeee00"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.2"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "466d45dc38e15794ec7d5d63ec03d776a9aff36e"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.4+1"

[[deps.FastAlmostBandedMatrices]]
deps = ["ArrayInterface", "ArrayLayouts", "BandedMatrices", "ConcreteStructs", "LazyArrays", "LinearAlgebra", "MatrixFactorizations", "PrecompileTools", "Reexport"]
git-tree-sha1 = "3f03d94c71126b6cfe20d3cbcc41c5cd27e1c419"
uuid = "9d29842c-ecb8-4973-b1e9-a27b1157504e"
version = "0.1.4"

[[deps.FastBroadcast]]
deps = ["ArrayInterface", "LinearAlgebra", "Polyester", "Static", "StaticArrayInterface", "StrideArraysCore"]
git-tree-sha1 = "a6e756a880fc419c8b41592010aebe6a5ce09136"
uuid = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
version = "0.2.8"

[[deps.FastClosures]]
git-tree-sha1 = "acebe244d53ee1b461970f8910c235b259e772ef"
uuid = "9aa1b823-49e4-5ca5-8b0f-3971ec8bab6a"
version = "0.3.2"

[[deps.FastLapackInterface]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "cbf5edddb61a43669710cbc2241bc08b36d9e660"
uuid = "29a986be-02c6-4525-aec4-84b980013641"
version = "2.0.4"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "6a70198746448456524cb442b8af316927ff3e1a"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.13.0"
weakdeps = ["PDMats", "SparseArrays", "Statistics"]

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStatisticsExt = "Statistics"

[[deps.FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Requires", "Setfield", "SparseArrays"]
git-tree-sha1 = "73d1214fec245096717847c62d389a5d2ac86504"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.22.0"

    [deps.FiniteDiff.extensions]
    FiniteDiffBandedMatricesExt = "BandedMatrices"
    FiniteDiffBlockBandedMatricesExt = "BlockBandedMatrices"
    FiniteDiffStaticArraysExt = "StaticArrays"

    [deps.FiniteDiff.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "db16beca600632c95fc8aca29890d83788dd8b23"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.96+0"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "a2df1b776752e3f344e5116c06d75a10436ab853"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.38"
weakdeps = ["StaticArrays"]

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "5c1d8ae0efc6c2e7b1fc502cbe25def8f661b7bc"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.2+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1ed150b39aebcc805c26b93a8d0122c940f64ce2"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.14+0"

[[deps.FunctionWrappers]]
git-tree-sha1 = "d62485945ce5ae9c0c48f124a84998d755bae00e"
uuid = "069b7b12-0de2-55c6-9aab-29f3d0a68a2e"
version = "1.1.3"

[[deps.FunctionWrappersWrappers]]
deps = ["FunctionWrappers"]
git-tree-sha1 = "b104d487b34566608f8b4e1c39fb0b10aa279ff8"
uuid = "77dc65aa-8811-40c2-897b-53d922fa7daf"
version = "0.1.3"

[[deps.Functors]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "64d8e93700c7a3f28f717d265382d52fac9fa1c1"
uuid = "d9f16b24-f501-4c13-a1f2-28368ffc5196"
version = "0.4.12"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll", "libdecor_jll", "xkbcommon_jll"]
git-tree-sha1 = "532f9126ad901533af1d4f5c198867227a7bb077"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.4.0+1"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "2d6ca471a6c7b536127afccfa7564b5b39227fe0"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.5"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Preferences", "Printf", "Qt6Wayland_jll", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "p7zip_jll"]
git-tree-sha1 = "ee28ddcd5517d54e417182fec3886e7412d3926f"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.73.8"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "FreeType2_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt6Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "f31929b9e67066bee48eec8b03c0df47d31a74b3"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.73.8+0"

[[deps.GenericSchur]]
deps = ["LinearAlgebra", "Printf"]
git-tree-sha1 = "af49a0851f8113fcfae2ef5027c6d49d0acec39b"
uuid = "c145ed77-6b09-5dd9-b285-bf645a82121e"
version = "0.5.4"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "674ff0db93fffcd11a3573986e550d66cd4fd71f"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.80.5+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "1dc470db8b1131cfc7fb4c115de89fe391b9e780"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.12.0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "1336e07ba2eb75614c99496501a8f4b233e9fafe"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.10"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll"]
git-tree-sha1 = "401e4f3f30f43af2c8478fc008da50096ea5240f"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "8.3.1+0"

[[deps.HostCPUFeatures]]
deps = ["BitTwiddlingConvenienceFunctions", "IfElse", "Libdl", "Static"]
git-tree-sha1 = "8e070b599339d622e9a081d17230d74a5c473293"
uuid = "3e5b6fbb-0976-4d2c-9146-d79de83f2fb0"
version = "0.1.17"

[[deps.HypergeometricFunctions]]
deps = ["LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "b1c2585431c382e3fe5805874bda6aea90a95de9"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.25"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[deps.Inflate]]
git-tree-sha1 = "d1b1b796e47d94588b3757fe84fbf65a5ec4a80d"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.5"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl"]
git-tree-sha1 = "10bd689145d2c3b2a9844005d01087cc1194e79e"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2024.2.1+0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLFzf]]
deps = ["Pipe", "REPL", "Random", "fzf_jll"]
git-tree-sha1 = "39d64b09147620f5ffbf6b2d3255be3c901bec63"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.8"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "be3dc50a92e5a386872a493a10050136d4703f9b"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.6.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "25ee0be4d43d0269027024d75a24c24d6c6e590c"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.0.4+0"

[[deps.JumpProcesses]]
deps = ["ArrayInterface", "DataStructures", "DiffEqBase", "DocStringExtensions", "FunctionWrappers", "Graphs", "LinearAlgebra", "Markdown", "PoissonRandom", "Random", "RandomNumbers", "RecursiveArrayTools", "Reexport", "SciMLBase", "StaticArrays", "UnPack"]
git-tree-sha1 = "c451feb97251965a9fe40bacd62551a72cc5902c"
uuid = "ccbc3e58-028d-4f4c-8cd5-9ae44345cda5"
version = "9.10.1"
weakdeps = ["FastBroadcast"]

    [deps.JumpProcesses.extensions]
    JumpProcessFastBroadcastExt = "FastBroadcast"

[[deps.KLU]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse_jll"]
git-tree-sha1 = "884c2968c2e8e7e6bf5956af88cb46aa745c854b"
uuid = "ef3ab10e-7fda-4108-b977-705223b18434"
version = "0.4.1"

[[deps.Krylov]]
deps = ["LinearAlgebra", "Printf", "SparseArrays"]
git-tree-sha1 = "4f20a2df85a9e5d55c9e84634bbf808ed038cabd"
uuid = "ba0b0d4f-ebba-5204-a429-3ac8c609bfb7"
version = "0.9.8"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "170b660facf5df5de098d866564877e119141cbd"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.2+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "36bdbc52f13a7d1dcb0f3cd694e01677a515655b"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "4.0.0+0"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "78211fb6cbc872f77cad3fc0b6cf647d923f4929"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "18.1.7+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "854a9c268c43b77b0a27f22d7fab8d33cdb3a731"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.2+1"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.Latexify]]
deps = ["Format", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Requires"]
git-tree-sha1 = "ce5f5621cac23a86011836badfedf664a612cee4"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.5"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SparseArraysExt = "SparseArrays"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LayoutPointers]]
deps = ["ArrayInterface", "LinearAlgebra", "ManualMemory", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "a9eaadb366f5493a5654e843864c13d8b107548c"
uuid = "10f19ff3-798f-405d-979b-55457f8fc047"
version = "0.1.17"

[[deps.Lazy]]
deps = ["MacroTools"]
git-tree-sha1 = "1370f8202dac30758f3c345f9909b97f53d87d3f"
uuid = "50d2b5c4-7a5e-59d5-8109-a42b560f39c0"
version = "0.15.1"

[[deps.LazyArrays]]
deps = ["ArrayLayouts", "FillArrays", "LinearAlgebra", "MacroTools", "MatrixFactorizations", "SparseArrays"]
git-tree-sha1 = "35079a6a869eecace778bcda8641f9a54ca3a828"
uuid = "5078a376-72f3-5289-bfd5-ec5146d43c02"
version = "1.10.0"
weakdeps = ["StaticArrays"]

    [deps.LazyArrays.extensions]
    LazyArraysStaticArraysExt = "StaticArrays"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LevyArea]]
deps = ["LinearAlgebra", "Random", "SpecialFunctions"]
git-tree-sha1 = "56513a09b8e0ae6485f34401ea9e2f31357958ec"
uuid = "2d8b4e74-eb68-11e8-0fb9-d5eb67b50637"
version = "1.0.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll"]
git-tree-sha1 = "8be878062e0ffa2c3f67bb58a595375eda5de80b"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.11.0+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "6f73d1dd803986947b2c750138528a999a6c7733"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.6.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c6ce1e19f3aec9b59186bdf06cdf3c4fc5f5f3e6"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.50.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "61dfdba58e585066d8bce214c5a51eaa0539f269"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+1"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "0c4f9c4f1a50d8f35048fa0532dabbadf702f81e"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.40.1+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "b404131d06f7886402758c9ce2214b636eb4d54a"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.7.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "5ee6203157c120d79034c748a2acba45b82b8807"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.40.1+0"

[[deps.LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "Printf"]
git-tree-sha1 = "e4c3be53733db1051cc15ecf573b1042b3a712a1"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.3.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LinearSolve]]
deps = ["ArrayInterface", "ConcreteStructs", "DocStringExtensions", "EnumX", "FastLapackInterface", "GPUArraysCore", "InteractiveUtils", "KLU", "Krylov", "Libdl", "LinearAlgebra", "MKL_jll", "PrecompileTools", "Preferences", "RecursiveFactorization", "Reexport", "SciMLBase", "SciMLOperators", "Setfield", "SparseArrays", "Sparspak", "StaticArraysCore", "UnPack"]
git-tree-sha1 = "6f8e084deabe3189416c4e505b1c53e1b590cae8"
uuid = "7ed4a6bd-45f5-4d41-b270-4a48e9bafcae"
version = "2.22.1"

    [deps.LinearSolve.extensions]
    LinearSolveBandedMatricesExt = "BandedMatrices"
    LinearSolveBlockDiagonalsExt = "BlockDiagonals"
    LinearSolveCUDAExt = "CUDA"
    LinearSolveEnzymeExt = ["Enzyme", "EnzymeCore"]
    LinearSolveFastAlmostBandedMatricesExt = ["FastAlmostBandedMatrices"]
    LinearSolveHYPREExt = "HYPRE"
    LinearSolveIterativeSolversExt = "IterativeSolvers"
    LinearSolveKernelAbstractionsExt = "KernelAbstractions"
    LinearSolveKrylovKitExt = "KrylovKit"
    LinearSolveMetalExt = "Metal"
    LinearSolvePardisoExt = "Pardiso"
    LinearSolveRecursiveArrayToolsExt = "RecursiveArrayTools"

    [deps.LinearSolve.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockDiagonals = "0a1fb500-61f7-11e9-3c65-f5ef3456f9f0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    FastAlmostBandedMatrices = "9d29842c-ecb8-4973-b1e9-a27b1157504e"
    HYPRE = "b5ffcf37-a2bd-41ab-a3da-4bd9bc8ad771"
    IterativeSolvers = "42fd0dbc-a981-5370-80f2-aaf504508153"
    KernelAbstractions = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
    KrylovKit = "0b1a1467-8014-51b9-945f-bf0ae24f4b77"
    Metal = "dde4c033-4e86-420c-a63e-0dd931031962"
    Pardiso = "46dd5b70-b6fb-5a00-ae2d-e8fea33afaf2"
    RecursiveArrayTools = "731186ca-8d62-57ce-b412-fbd966d074cd"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "a2d09619db4e765091ee5c6ffe8872849de0feea"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.28"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "f02b56007b064fbfddb4c9cd60161b6dd0f40df3"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.1.0"

[[deps.LoopVectorization]]
deps = ["ArrayInterface", "CPUSummary", "CloseOpenIntervals", "DocStringExtensions", "HostCPUFeatures", "IfElse", "LayoutPointers", "LinearAlgebra", "OffsetArrays", "PolyesterWeave", "PrecompileTools", "SIMDTypes", "SLEEFPirates", "Static", "StaticArrayInterface", "ThreadingUtilities", "UnPack", "VectorizationBase"]
git-tree-sha1 = "8084c25a250e00ae427a379a5b607e7aed96a2dd"
uuid = "bdcacae8-1622-11e9-2a5c-532679323890"
version = "0.12.171"

    [deps.LoopVectorization.extensions]
    ForwardDiffExt = ["ChainRulesCore", "ForwardDiff"]
    SpecialFunctionsExt = "SpecialFunctions"

    [deps.LoopVectorization.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "oneTBB_jll"]
git-tree-sha1 = "f046ccd0c6db2832a9f639e2c669c6fe867e5f4f"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2024.2.0+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "2fa9ee3e63fd3a4f7a9a4f4744a52f4856de82df"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.13"

[[deps.ManualMemory]]
git-tree-sha1 = "bcaef4fc7a0cfe2cba636d84cda54b5e4e4ca3cd"
uuid = "d125e4d3-2237-4719-b19c-fa641b8a4667"
version = "0.1.8"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MatrixFactorizations]]
deps = ["ArrayLayouts", "LinearAlgebra", "Printf", "Random"]
git-tree-sha1 = "6731e0574fa5ee21c02733e397beb133df90de35"
uuid = "a3b82374-2e81-5b9e-98ce-41277c0e4c87"
version = "2.2.0"

[[deps.MaybeInplace]]
deps = ["ArrayInterface", "LinearAlgebra", "MacroTools"]
git-tree-sha1 = "54e2fdc38130c05b42be423e90da3bade29b74bd"
uuid = "bb5d69b7-63fc-4a16-80bd-7e42200c7bdb"
version = "0.1.4"
weakdeps = ["SparseArrays"]

    [deps.MaybeInplace.extensions]
    MaybeInplaceSparseArraysExt = "SparseArrays"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.MuladdMacro]]
git-tree-sha1 = "cac9cc5499c25554cba55cd3c30543cff5ca4fab"
uuid = "46d2c3a1-f734-5fdb-9937-b9b9aeba4221"
version = "0.2.4"

[[deps.NLSolversBase]]
deps = ["DiffResults", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "a0b464d183da839699f4c79e7606d9d186ec172c"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.8.3"

[[deps.NLsolve]]
deps = ["Distances", "LineSearches", "LinearAlgebra", "NLSolversBase", "Printf", "Reexport"]
git-tree-sha1 = "019f12e9a1a7880459d0173c182e6a99365d7ac1"
uuid = "2774e3e8-f4cf-5e23-947b-6d7e65073b56"
version = "4.5.1"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.NonlinearSolve]]
deps = ["ADTypes", "ArrayInterface", "ConcreteStructs", "DiffEqBase", "EnumX", "FastBroadcast", "FastClosures", "FiniteDiff", "ForwardDiff", "LazyArrays", "LineSearches", "LinearAlgebra", "LinearSolve", "MaybeInplace", "PrecompileTools", "Printf", "RecursiveArrayTools", "Reexport", "SciMLBase", "SciMLOperators", "SimpleNonlinearSolve", "SparseArrays", "SparseDiffTools", "StaticArrays", "UnPack"]
git-tree-sha1 = "72b036b728461272ae1b1c3f7096cb4c319d8793"
uuid = "8913a72c-1f9b-4ce2-8d82-65094dcecaec"
version = "3.4.0"

    [deps.NonlinearSolve.extensions]
    NonlinearSolveBandedMatricesExt = "BandedMatrices"
    NonlinearSolveFastLevenbergMarquardtExt = "FastLevenbergMarquardt"
    NonlinearSolveFixedPointAccelerationExt = "FixedPointAcceleration"
    NonlinearSolveLeastSquaresOptimExt = "LeastSquaresOptim"
    NonlinearSolveMINPACKExt = "MINPACK"
    NonlinearSolveNLsolveExt = "NLsolve"
    NonlinearSolveSIAMFANLEquationsExt = "SIAMFANLEquations"
    NonlinearSolveSpeedMappingExt = "SpeedMapping"
    NonlinearSolveSymbolicsExt = "Symbolics"
    NonlinearSolveZygoteExt = "Zygote"

    [deps.NonlinearSolve.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    FastLevenbergMarquardt = "7a0df574-e128-4d35-8cbd-3d84502bf7ce"
    FixedPointAcceleration = "817d07cb-a79a-5c30-9a31-890123675176"
    LeastSquaresOptim = "0fc2ff8b-aaa3-5acd-a817-1944a5e08891"
    MINPACK = "4854310b-de5a-5eb6-a2a5-c1dee2bd17f9"
    NLsolve = "2774e3e8-f4cf-5e23-947b-6d7e65073b56"
    SIAMFANLEquations = "084e46ad-d928-497d-ad5e-07fa361a48c4"
    SpeedMapping = "f1835b91-879b-4a3f-a438-e4baacf14412"

    Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"


[[deps.OffsetArrays]]
git-tree-sha1 = "1a27764e945a152f7ca7efa04de513d473e9542e"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.14.1"
weakdeps = ["Adapt"]

    [deps.OffsetArrays.extensions]
    OffsetArraysAdaptExt = "Adapt"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "38cb508d080d21dc1128f7fb04f20387ed4c0af4"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.3"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7493f61f55a6cce7325f197443aa80d32554ba10"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.15+1"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Optim]]
deps = ["Compat", "FillArrays", "ForwardDiff", "LineSearches", "LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "PositiveFactorizations", "Printf", "SparseArrays", "StatsBase"]
git-tree-sha1 = "ab7edad78cdef22099f43c54ef77ac63c2c9cc64"
uuid = "429524aa-4258-5aef-a3af-852621145aeb"
version = "1.10.0"

    [deps.Optim.extensions]
    OptimMOIExt = "MathOptInterface"

    [deps.Optim.weakdeps]
    MathOptInterface = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6703a85cb3781bd5909d48730a67205f3f31a575"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.3+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.OrdinaryDiffEq]]
deps = ["ADTypes", "Adapt", "ArrayInterface", "DataStructures", "DiffEqBase", "DocStringExtensions", "ExponentialUtilities", "FastBroadcast", "FastClosures", "FillArrays", "FiniteDiff", "ForwardDiff", "FunctionWrappersWrappers", "IfElse", "InteractiveUtils", "LineSearches", "LinearAlgebra", "LinearSolve", "Logging", "LoopVectorization", "MacroTools", "MuladdMacro", "NonlinearSolve", "Polyester", "PreallocationTools", "PrecompileTools", "Preferences", "RecursiveArrayTools", "Reexport", "SciMLBase", "SciMLOperators", "SimpleNonlinearSolve", "SimpleUnPack", "SparseArrays", "SparseDiffTools", "StaticArrayInterface", "StaticArrays", "TruncatedStacktraces"]
git-tree-sha1 = "96ae028da53cdfe24712ab015a6f854cfd7609c0"
uuid = "1dea7af3-3e70-54e6-95c3-0bf5283fa5ed"
version = "6.66.0"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+0"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "949347156c25054de2db3b166c52ac4728cbad65"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.31"

[[deps.PackageExtensionCompat]]
git-tree-sha1 = "fb28e33b8a95c4cee25ce296c817d89cc2e53518"
uuid = "65ce6f38-6b18-4e1d-a461-8949797d7930"
version = "1.0.2"
weakdeps = ["Requires", "TOML"]

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e127b609fb9ecba6f201ba7ab753d5a605d53801"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.54.1+0"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "35621f10a7531bc8fa58f74610b1bfb70a3cfc6b"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.43.4+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.2"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "41031ef3a1be6f5bbbf3e8073f210556daeae5ca"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.3.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "StableRNGs", "Statistics"]
git-tree-sha1 = "3ca9a356cd2e113c420f2c13bea19f8d3fb1cb18"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.3"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "PrecompileTools", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "TOML", "UUIDs", "UnicodeFun", "UnitfulLatexify", "Unzip"]
git-tree-sha1 = "dae01f8c2e069a683d3a6e17bbae5070ab94786f"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.40.9"

    [deps.Plots.extensions]
    FileIOExt = "FileIO"
    GeometryBasicsExt = "GeometryBasics"
    IJuliaExt = "IJulia"
    ImageInTerminalExt = "ImageInTerminal"
    UnitfulExt = "Unitful"

    [deps.Plots.weakdeps]
    FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
    GeometryBasics = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"
    ImageInTerminal = "d8c32880-2388-543b-8c61-d9f865259254"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "eba4810d5e6a01f612b948c9fa94f905b49087b0"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.60"

[[deps.PoissonRandom]]
deps = ["Random"]
git-tree-sha1 = "a0f1159c33f846aa77c3f30ebbc69795e5327152"
uuid = "e409e4f3-bfea-5376-8464-e040bb5c01ab"
version = "0.4.4"

[[deps.Polyester]]
deps = ["ArrayInterface", "BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "ManualMemory", "PolyesterWeave", "Static", "StaticArrayInterface", "StrideArraysCore", "ThreadingUtilities"]
git-tree-sha1 = "6d38fea02d983051776a856b7df75b30cf9a3c1f"
uuid = "f517fe37-dbe3-4b94-8317-1923a5111588"
version = "0.7.16"

[[deps.PolyesterWeave]]
deps = ["BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "Static", "ThreadingUtilities"]
git-tree-sha1 = "645bed98cd47f72f67316fd42fc47dee771aefcd"
uuid = "1d0040c9-8b98-4ee7-8388-3f51789ca0ad"
version = "0.2.2"


[[deps.Polynomials]]
deps = ["LinearAlgebra", "RecipesBase", "Requires", "Setfield", "SparseArrays"]
git-tree-sha1 = "1a9cfb2dc2c2f1bd63f1906d72af39a79b49b736"
uuid = "f27b6e38-b328-58d1-80ce-0feddd5e7a45"
version = "4.0.11"

    [deps.Polynomials.extensions]
    PolynomialsChainRulesCoreExt = "ChainRulesCore"
    PolynomialsFFTWExt = "FFTW"
    PolynomialsMakieCoreExt = "MakieCore"
    PolynomialsMutableArithmeticsExt = "MutableArithmetics"

    [deps.Polynomials.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    FFTW = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
    MakieCore = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
    MutableArithmetics = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"


[[deps.PositiveFactorizations]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "17275485f373e6673f7e7f97051f703ed5b15b20"
uuid = "85a6dd25-e78a-55b7-8502-1745935b8125"
version = "0.2.4"

[[deps.PreallocationTools]]
deps = ["Adapt", "ArrayInterface", "ForwardDiff", "Requires"]
git-tree-sha1 = "01ac95fca7daabe77a9cb705862bd87016af9ddb"
uuid = "d236fae5-4411-538c-8e31-a6e3d9e00b46"
version = "0.4.13"

    [deps.PreallocationTools.extensions]
    PreallocationToolsReverseDiffExt = "ReverseDiff"

    [deps.PreallocationTools.weakdeps]
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.PtrArrays]]
git-tree-sha1 = "77a42d78b6a92df47ab37e177b2deac405e1c88f"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.2.1"

[[deps.Qt6Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Vulkan_Loader_jll", "Xorg_libSM_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_cursor_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "libinput_jll", "xkbcommon_jll"]
git-tree-sha1 = "492601870742dcd38f233b23c3ec629628c1d724"
uuid = "c0090381-4147-56d7-9ebc-da0b1113ec56"
version = "6.7.1+1"

[[deps.Qt6Declarative_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll", "Qt6ShaderTools_jll"]
git-tree-sha1 = "e5dd466bf2569fe08c91a2cc29c1003f4797ac3b"
uuid = "629bc702-f1f5-5709-abd5-49b8460ea067"
version = "6.7.1+2"

[[deps.Qt6ShaderTools_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll"]
git-tree-sha1 = "1a180aeced866700d4bebc3120ea1451201f16bc"
uuid = "ce943373-25bb-56aa-8eca-768745ed7b5a"
version = "6.7.1+1"

[[deps.Qt6Wayland_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll", "Qt6Declarative_jll"]
git-tree-sha1 = "729927532d48cf79f49070341e1d918a65aba6b0"
uuid = "e99dba38-086e-5de3-a5b1-6e4c66e897c3"
version = "6.7.1+1"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "cda3b045cf9ef07a08ad46731f5a3165e56cf3da"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.11.1"

    [deps.QuadGK.extensions]
    QuadGKEnzymeExt = "Enzyme"

    [deps.QuadGK.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Random123]]
deps = ["Random", "RandomNumbers"]
git-tree-sha1 = "4743b43e5a9c4a2ede372de7061eed81795b12e7"
uuid = "74087812-796a-5b5d-8853-05524746bad3"
version = "1.7.0"

[[deps.RandomNumbers]]
deps = ["Random"]
git-tree-sha1 = "c6ec94d2aaba1ab2ff983052cf6a606ca5985902"
uuid = "e6cf234a-135c-5ec9-84dd-332b85af5143"
version = "1.6.0"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "PrecompileTools", "RecipesBase"]
git-tree-sha1 = "45cf9fd0ca5839d06ef333c8201714e888486342"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.12"

[[deps.RecursiveArrayTools]]
deps = ["Adapt", "ArrayInterface", "DocStringExtensions", "GPUArraysCore", "IteratorInterfaceExtensions", "LinearAlgebra", "RecipesBase", "Requires", "SparseArrays", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface", "Tables"]
git-tree-sha1 = "27ee1c03e732c488ecce1a25f0d7da9b5d936574"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "3.3.3"

    [deps.RecursiveArrayTools.extensions]
    RecursiveArrayToolsFastBroadcastExt = "FastBroadcast"
    RecursiveArrayToolsMeasurementsExt = "Measurements"
    RecursiveArrayToolsMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    RecursiveArrayToolsTrackerExt = "Tracker"
    RecursiveArrayToolsZygoteExt = "Zygote"

    [deps.RecursiveArrayTools.weakdeps]
    FastBroadcast = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.RecursiveFactorization]]
deps = ["LinearAlgebra", "LoopVectorization", "Polyester", "PrecompileTools", "StrideArraysCore", "TriangularSolve"]
git-tree-sha1 = "c04dacfc546591d43c39dc529c922d6a06a5a694"
uuid = "f2c3362d-daeb-58d1-803e-2bc74f2840b4"
version = "0.2.22"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.ResettableStacks]]
deps = ["StaticArrays"]
git-tree-sha1 = "256eeeec186fa7f26f2801732774ccf277f05db9"
uuid = "ae5879a3-cd67-5da8-be7f-38c6eb64a37b"
version = "1.1.1"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "852bd0f55565a9e973fcfee83a84413270224dc4"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.8.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "58cdd8fb2201a6267e1db87ff148dd6c1dbd8ad8"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.5.1+0"

[[deps.RuntimeGeneratedFunctions]]
deps = ["ExprTools", "SHA", "Serialization"]
git-tree-sha1 = "6aacc5eefe8415f47b3e34214c1d79d2674a0ba2"
uuid = "7e49a35a-f44a-4d26-94aa-eba1b4ca6b47"
version = "0.5.12"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMDTypes]]
git-tree-sha1 = "330289636fb8107c5f32088d2741e9fd7a061a5c"
uuid = "94e857df-77ce-4151-89e5-788b33177be4"
version = "0.1.0"

[[deps.SLEEFPirates]]
deps = ["IfElse", "Static", "VectorizationBase"]
git-tree-sha1 = "456f610ca2fbd1c14f5fcf31c6bfadc55e7d66e0"
uuid = "476501e8-09a2-5ece-8869-fb82de89a1fa"
version = "0.6.43"

[[deps.SciMLBase]]
deps = ["ADTypes", "ArrayInterface", "CommonSolve", "ConstructionBase", "Distributed", "DocStringExtensions", "EnumX", "FillArrays", "FunctionWrappersWrappers", "IteratorInterfaceExtensions", "LinearAlgebra", "Logging", "Markdown", "PrecompileTools", "Preferences", "Printf", "RecipesBase", "RecursiveArrayTools", "Reexport", "RuntimeGeneratedFunctions", "SciMLOperators", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface", "Tables", "TruncatedStacktraces"]
git-tree-sha1 = "09324a0ae70c52a45b91b236c62065f78b099c37"
uuid = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
version = "2.15.2"

    [deps.SciMLBase.extensions]
    SciMLBaseChainRulesCoreExt = "ChainRulesCore"
    SciMLBasePartialFunctionsExt = "PartialFunctions"
    SciMLBasePyCallExt = "PyCall"
    SciMLBasePythonCallExt = "PythonCall"
    SciMLBaseRCallExt = "RCall"
    SciMLBaseZygoteExt = "Zygote"

    [deps.SciMLBase.weakdeps]
    ChainRules = "082447d4-558c-5d27-93f4-14fc19e9eca2"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    PartialFunctions = "570af359-4316-4cb7-8c74-252c00c2016b"
    PyCall = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
    PythonCall = "6099a3de-0909-46bc-b1f4-468b9a2dfc0d"
    RCall = "6f49c342-dc21-5d91-9882-a32aef131414"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.SciMLOperators]]
deps = ["ArrayInterface", "DocStringExtensions", "Lazy", "LinearAlgebra", "Setfield", "SparseArrays", "StaticArraysCore", "Tricks"]
git-tree-sha1 = "51ae235ff058a64815e0a2c34b1db7578a06813d"
uuid = "c0aeaf25-5076-4817-a8d5-81caf7dfa961"
version = "0.3.7"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "f305871d2f381d21527c770d4788c06c097c9bc1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.2.0"

[[deps.SimpleNonlinearSolve]]
deps = ["ADTypes", "ArrayInterface", "ConcreteStructs", "DiffEqBase", "FastClosures", "FiniteDiff", "ForwardDiff", "LinearAlgebra", "MaybeInplace", "PrecompileTools", "Reexport", "SciMLBase", "StaticArraysCore"]
git-tree-sha1 = "df8266e0d4960d61325db8c54fad3fa95712b57e"
uuid = "727e6d20-b764-4bd8-a329-72de5adea6c7"
version = "1.4.0"

    [deps.SimpleNonlinearSolve.extensions]
    SimpleNonlinearSolveChainRulesCoreExt = "ChainRulesCore"
    SimpleNonlinearSolvePolyesterForwardDiffExt = "PolyesterForwardDiff"
    SimpleNonlinearSolveStaticArraysExt = "StaticArrays"

    [deps.SimpleNonlinearSolve.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    PolyesterForwardDiff = "98d1487c-24ca-40b6-b7ab-df2af84e126b"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.SimpleUnPack]]
git-tree-sha1 = "58e6353e72cde29b90a69527e56df1b5c3d8c437"
uuid = "ce78b400-467f-4804-87d8-8f486da07d0a"
version = "1.1.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SparseDiffTools]]
deps = ["ADTypes", "Adapt", "ArrayInterface", "Compat", "DataStructures", "FiniteDiff", "ForwardDiff", "Graphs", "LinearAlgebra", "PackageExtensionCompat", "Random", "Reexport", "SciMLOperators", "Setfield", "SparseArrays", "StaticArrayInterface", "StaticArrays", "Tricks", "UnPack", "VertexSafeGraphs"]
git-tree-sha1 = "cce98ad7c896e52bb0eded174f02fc2a29c38477"
uuid = "47a9eef4-7e08-11e9-0b38-333d64bd3804"
version = "2.18.0"

    [deps.SparseDiffTools.extensions]
    SparseDiffToolsEnzymeExt = "Enzyme"
    SparseDiffToolsPolyesterExt = "Polyester"
    SparseDiffToolsPolyesterForwardDiffExt = "PolyesterForwardDiff"
    SparseDiffToolsSymbolicsExt = "Symbolics"
    SparseDiffToolsZygoteExt = "Zygote"

    [deps.SparseDiffTools.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    Polyester = "f517fe37-dbe3-4b94-8317-1923a5111588"
    PolyesterForwardDiff = "98d1487c-24ca-40b6-b7ab-df2af84e126b"
    Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.Sparspak]]
deps = ["Libdl", "LinearAlgebra", "Logging", "OffsetArrays", "Printf", "SparseArrays", "Test"]
git-tree-sha1 = "342cf4b449c299d8d1ceaf00b7a49f4fbc7940e7"
uuid = "e56a9233-b9d6-4f03-8d0f-1825330902ac"
version = "0.3.9"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "2f5d4697f21388cbe1ff299430dd169ef97d7e14"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.4.0"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.StableRNGs]]
deps = ["Random"]
git-tree-sha1 = "83e6cce8324d49dfaf9ef059227f91ed4441a8e5"
uuid = "860ef19b-820b-49d6-a774-d7a799459cd3"
version = "1.0.2"

[[deps.Static]]
deps = ["IfElse"]
git-tree-sha1 = "b366eb1eb68075745777d80861c6706c33f588ae"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.8.9"

[[deps.StaticArrayInterface]]
deps = ["ArrayInterface", "Compat", "IfElse", "LinearAlgebra", "PrecompileTools", "Requires", "Static"]
git-tree-sha1 = "c3668ff1a3e4ddf374fc4f8c25539ce7194dcc39"
uuid = "0d7ed370-da01-4f52-bd93-41d350b8b718"
version = "1.6.0"
weakdeps = ["OffsetArrays", "StaticArrays"]

    [deps.StaticArrayInterface.extensions]
    StaticArrayInterfaceOffsetArraysExt = "OffsetArrays"
    StaticArrayInterfaceStaticArraysExt = "StaticArrays"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "777657803913ffc7e8cc20f0fd04b634f871af8f"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.8"

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

    [deps.StaticArrays.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StaticArraysCore]]
git-tree-sha1 = "192954ef1208c7019899fbf8049e717f92959682"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.3"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "5cf7606d6cef84b543b483848d4ae08ad9832b21"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.3"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "b423576adc27097764a90e163157bcfc9acf0f46"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.3.2"

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

    [deps.StatsFuns.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.SteadyStateDiffEq]]
deps = ["ConcreteStructs", "DiffEqBase", "DiffEqCallbacks", "LinearAlgebra", "Reexport", "SciMLBase"]
git-tree-sha1 = "a735fd5053724cf4de31c81b4e2cc429db844be5"
uuid = "9672c7b4-1e72-59bd-8a11-6ac3964bc41f"
version = "2.0.1"

[[deps.StochasticDiffEq]]
deps = ["Adapt", "ArrayInterface", "DataStructures", "DiffEqBase", "DiffEqNoiseProcess", "DocStringExtensions", "FiniteDiff", "ForwardDiff", "JumpProcesses", "LevyArea", "LinearAlgebra", "Logging", "MuladdMacro", "NLsolve", "OrdinaryDiffEq", "Random", "RandomNumbers", "RecursiveArrayTools", "Reexport", "SciMLBase", "SciMLOperators", "SparseArrays", "SparseDiffTools", "StaticArrays", "UnPack"]
git-tree-sha1 = "97e5d0b7e5ec2e68eec6626af97c59e9f6b6c3d0"
uuid = "789caeaf-c7a9-5a7d-9973-96adeb23e2a0"
version = "6.65.1"

[[deps.StrideArraysCore]]
deps = ["ArrayInterface", "CloseOpenIntervals", "IfElse", "LayoutPointers", "LinearAlgebra", "ManualMemory", "SIMDTypes", "Static", "StaticArrayInterface", "ThreadingUtilities"]
git-tree-sha1 = "f35f6ab602df8413a50c4a25ca14de821e8605fb"
uuid = "7792a7ef-975c-4747-a70f-980b88e8d1da"
version = "0.5.7"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.Sundials]]
deps = ["CEnum", "DataStructures", "DiffEqBase", "Libdl", "LinearAlgebra", "Logging", "PrecompileTools", "Reexport", "SciMLBase", "SparseArrays", "Sundials_jll"]
git-tree-sha1 = "e15f5a73f0d14b9079b807a9d1dac13e4302e997"
uuid = "c3572dad-4567-51f8-b174-8c6c989267f4"
version = "4.24.0"

[[deps.Sundials_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "OpenBLAS_jll", "Pkg", "SuiteSparse_jll"]
git-tree-sha1 = "04777432d74ec5bc91ca047c9e0e0fd7f81acdb6"
uuid = "fb77eaff-e24c-56d4-86b1-d163f2edb164"
version = "5.2.1+0"

[[deps.SymbolicIndexingInterface]]
git-tree-sha1 = "be414bfd80c2c91197823890c66ef4b74f5bf5fe"
uuid = "2efcf032-c050-4f8e-a9bb-153293bab1f5"

version = "0.3.35"

[[deps.SymbolicLimits]]
deps = ["SymbolicUtils"]
git-tree-sha1 = "fabf4650afe966a2ba646cabd924c3fd43577fc3"
uuid = "19f23fe9-fdab-4a78-91af-e7b7767979c3"
version = "0.2.2"

[[deps.SymbolicUtils]]
deps = ["AbstractTrees", "ArrayInterface", "Bijections", "ChainRulesCore", "Combinatorics", "ConstructionBase", "DataStructures", "DocStringExtensions", "DynamicPolynomials", "IfElse", "LinearAlgebra", "MultivariatePolynomials", "NaNMath", "Setfield", "SparseArrays", "SpecialFunctions", "StaticArrays", "SymbolicIndexingInterface", "TermInterface", "TimerOutputs", "Unityper"]
git-tree-sha1 = "04e9157537ba51dad58336976f8d04b9ab7122f0"
uuid = "d1185830-fcd6-423d-90d6-eec64667417b"
version = "3.7.2"

    [deps.SymbolicUtils.extensions]
    SymbolicUtilsLabelledArraysExt = "LabelledArrays"
    SymbolicUtilsReverseDiffExt = "ReverseDiff"

    [deps.SymbolicUtils.weakdeps]
    LabelledArrays = "2ee39098-c373-598a-b85f-a56591580800"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"

[[deps.Symbolics]]
deps = ["ADTypes", "ArrayInterface", "Bijections", "CommonWorldInvalidations", "ConstructionBase", "DataStructures", "DiffRules", "Distributions", "DocStringExtensions", "DomainSets", "DynamicPolynomials", "IfElse", "LaTeXStrings", "Latexify", "Libdl", "LinearAlgebra", "LogExpFunctions", "MacroTools", "Markdown", "NaNMath", "PrecompileTools", "Primes", "RecipesBase", "Reexport", "RuntimeGeneratedFunctions", "SciMLBase", "Setfield", "SparseArrays", "SpecialFunctions", "StaticArraysCore", "SymbolicIndexingInterface", "SymbolicLimits", "SymbolicUtils", "TermInterface"]
git-tree-sha1 = "2f8e9bb64b0a1d658fcf4f3c7bc145284ad0f69b"
uuid = "0c5d862f-8b57-4792-8d23-62f2024744c7"
version = "6.20.0"

    [deps.Symbolics.extensions]
    SymbolicsForwardDiffExt = "ForwardDiff"
    SymbolicsGroebnerExt = "Groebner"
    SymbolicsLuxExt = "Lux"
    SymbolicsNemoExt = "Nemo"
    SymbolicsPreallocationToolsExt = ["PreallocationTools", "ForwardDiff"]
    SymbolicsSymPyExt = "SymPy"

    [deps.Symbolics.weakdeps]
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    Groebner = "0b43b601-686d-58a3-8a1c-6623616c7cd4"
    Lux = "b2108857-7c20-44ae-9111-449ecde12c47"
    Nemo = "2edaba10-b0f1-5616-af89-8c11ac63239a"
    PreallocationTools = "d236fae5-4411-538c-8e31-a6e3d9e00b46"
    SymPy = "24249f21-da20-56a4-8eb1-6a02cf4ae2e6"

version = "0.3.1"


[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "598cd7c1f68d1e205689b1c2fe65a9f85846f297"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.ThreadingUtilities]]
deps = ["ManualMemory"]
git-tree-sha1 = "eda08f7e9818eb53661b3deb74e3159460dfbc27"
uuid = "8290d209-cae3-49c0-8002-c8c24d57dab5"
version = "0.5.2"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.TriangularSolve]]
deps = ["CloseOpenIntervals", "IfElse", "LayoutPointers", "LinearAlgebra", "LoopVectorization", "Polyester", "Static", "VectorizationBase"]
git-tree-sha1 = "fadebab77bf3ae041f77346dd1c290173da5a443"
uuid = "d5829a12-d9aa-46ab-831f-fb7c9ab06edf"
version = "0.1.20"

[[deps.Tricks]]
git-tree-sha1 = "7822b97e99a1672bfb1b49b668a6d46d58d8cbcb"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.9"

[[deps.TruncatedStacktraces]]
deps = ["InteractiveUtils", "MacroTools", "Preferences"]
git-tree-sha1 = "ea3e54c2bdde39062abf5a9758a23735558705e1"
uuid = "781d530d-4396-4725-bb49-402e4bee1e77"
version = "1.4.0"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "d95fe458f26209c66a187b1114df96fd70839efd"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.21.0"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.UnitfulLatexify]]
deps = ["LaTeXStrings", "Latexify", "Unitful"]
git-tree-sha1 = "975c354fcd5f7e1ddcc1f1a23e6e091d99e99bc8"
uuid = "45397f5d-5981-4c77-b2b3-fc36d6e9b728"
version = "1.6.4"

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.VectorizationBase]]
deps = ["ArrayInterface", "CPUSummary", "HostCPUFeatures", "IfElse", "LayoutPointers", "Libdl", "LinearAlgebra", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "4ab62a49f1d8d9548a1c8d1a75e5f55cf196f64e"
uuid = "3d5dd08c-fd9d-11e8-17fa-ed2836048c2f"
version = "0.21.71"

[[deps.VertexSafeGraphs]]
deps = ["Graphs"]
git-tree-sha1 = "8351f8d73d7e880bfc042a8b6922684ebeafb35c"
uuid = "19fa3120-7c27-5ec5-8db8-b0b0aa330d6f"
version = "0.2.0"

[[deps.Vulkan_Loader_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Wayland_jll", "Xorg_libX11_jll", "Xorg_libXrandr_jll", "xkbcommon_jll"]
git-tree-sha1 = "2f0486047a07670caad3a81a075d2e518acc5c59"
uuid = "a44049a8-05dd-5a78-86c9-5fde0876e88c"
version = "1.3.243+0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "7558e29847e99bc3f04d6569e82d0f5c54460703"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+1"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "93f43ab61b16ddfb2fd3bb13b3ce241cafb0e6c9"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.31.0+0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "a2fccc6559132927d4c5dc183e3e01048c6dcbd6"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.5+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "a54ee957f4c86b526460a720dbc882fa5edcbefc"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.41+0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "15e637a697345f6743674f1322beefbc5dcd5cfc"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.6.3+0"

[[deps.Xorg_libICE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "326b4fea307b0b39892b3e85fa451692eda8d46c"
uuid = "f67eecfb-183a-506d-b269-f58e52b52d7c"
version = "1.1.1+0"

[[deps.Xorg_libSM_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libICE_jll"]
git-tree-sha1 = "3796722887072218eabafb494a13c963209754ce"
uuid = "c834827a-8449-5923-a945-d239c165b7dd"
version = "1.2.4+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "afead5aba5aa507ad5a3bf01f58f82c8d1403495"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.6+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6035850dcc70518ca32f012e46015b9beeda49d8"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.11+0"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "34d526d318358a859d7de23da945578e8e8727b7"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.4+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "d2d1a5c49fae4ba39983f63de6afcbea47194e85"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.6+0"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "47e45cd78224c53109495b3e324df0c37bb61fbe"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.11+0"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8fdda4c692503d44d04a0603d9ac0982054635f9"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.1+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "bcd466676fef0878338c61e655629fa7bbc69d8e"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.0+0"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "730eeca102434283c50ccf7d1ecdadf521a765a4"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.2+0"

[[deps.Xorg_xcb_util_cursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_jll", "Xorg_xcb_util_renderutil_jll"]
git-tree-sha1 = "04341cb870f29dcd5e39055f895c39d016e18ccd"
uuid = "e920d4aa-a673-5f3a-b3d7-f755a4d47c43"
version = "0.1.4+0"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "330f955bc41bb8f5270a369c473fc4a5a4e4d3cb"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.6+0"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "691634e5453ad362044e2ad653e79f3ee3bb98c3"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.39.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e92a1a012a10506618f10b7047e478403a046c77"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.5.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "555d1076590a6cc2fdee2ef1469451f872d8b41b"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.6+1"

[[deps.eudev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "gperf_jll"]
git-tree-sha1 = "431b678a28ebb559d224c0b6b6d01afce87c51ba"
uuid = "35ca27e7-8b34-5b7f-bca9-bdc33f59eb06"
version = "3.2.9+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "936081b536ae4aa65415d869287d43ef3cb576b2"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.53.0+0"

[[deps.gperf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3516a5630f741c9eecb3720b1ec9d8edc3ecc033"
uuid = "1a1c6b14-54f6-533d-8383-74cd7377aa70"
version = "3.1.1+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1827acba325fdcdf1d2647fc8d5301dd9ba43a9d"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.9.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "e17c115d55c5fbb7e52ebedb427a0dca79d4484e"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.2+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+0"

[[deps.libdecor_jll]]
deps = ["Artifacts", "Dbus_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pango_jll", "Wayland_jll", "xkbcommon_jll"]
git-tree-sha1 = "9bf7903af251d2050b467f76bdbe57ce541f7f4f"
uuid = "1183f4f0-6f2a-5f1a-908b-139f9cdfea6f"
version = "0.2.2+0"

[[deps.libevdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "141fe65dc3efabb0b1d5ba74e91f6ad26f84cc22"
uuid = "2db6ffa8-e38f-5e21-84af-90c45d0032cc"
version = "1.11.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a22cf860a7d27e4f3498a0fe0811a7957badb38"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.3+0"

[[deps.libinput_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "eudev_jll", "libevdev_jll", "mtdev_jll"]
git-tree-sha1 = "ad50e5b90f222cfe78aa3d5183a20a12de1322ce"
uuid = "36db933b-70db-51c0-b978-0f229ee0e533"
version = "1.18.0+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "b70c870239dc3d7bc094eb2d6be9b73d27bef280"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.44+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "490376214c4721cdaca654041f635213c6165cb3"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+2"

[[deps.mtdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "814e154bdb7be91d78b6802843f76b6ece642f11"
uuid = "009596ad-96f7-51b1-9f1b-5ce2d5e8a71e"
version = "1.1.6+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.oneTBB_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7d0ea0f4895ef2f5cb83645fa689e52cb55cf493"
uuid = "1317d2d5-d96f-522e-a858-c73665f53c3e"
version = "2021.12.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "9c304562909ab2bab0262639bd4f444d7bc2be37"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+1"
"""

# ╔═╡ Cell order:
# ╟─31846f28-a3d2-11ef-1308-dd1e47ea992b
# ╟─b022e54e-d9a3-450e-a601-047a57f53b10
# ╟─721ae26b-573f-4b01-8f01-60d65ceeafcf
# ╟─a90f228e-2e72-44cb-8b7f-dbea8e53f7fb
# ╠═252baa9e-2a73-434f-a33c-836464dd9b01
# ╟─4bd6bcb2-6127-45b9-8032-97a876288fe4
# ╟─fb28df9e-1ea5-4481-a7bd-28300499dfab
# ╟─5fceba2f-06eb-4173-8a64-92b4b9ff7b7a
# ╟─da658b1f-f72d-48df-b2d2-0de17250219e
# ╟─72f95577-4ec2-4464-a5f8-da59e64523e5
# ╟─96ff62f9-ebdf-44a0-b9bd-1703a1f7c4d2
# ╟─31fa6de2-b739-4c0e-a46e-cf3736d9d429
# ╟─5e756abf-619f-44ff-8cdf-273344ce4686
# ╟─8f447492-cbf1-4abc-a542-389add65da81
# ╟─d8f88fee-bb8e-4dd1-8deb-c5b070b270b2
# ╠═dbee1abf-7858-4ace-a339-2fab9064968b
# ╟─a97e1d99-69fa-44fe-9554-d41f4a2d2dfa
# ╠═adb492a3-2d99-4082-b1b9-a421389204df
# ╟─078a6bf7-8fbb-4cff-93d5-21c96655565a
# ╟─5599267b-a4ed-4995-aa17-7714bbed8e78

# ╠═a575e105-2142-460f-9c98-37486e00c361
# ╟─f77361b9-a981-412d-8efe-3629c4909985

# ╟─a575e105-2142-460f-9c98-37486e00c361
# ╠═f77361b9-a981-412d-8efe-3629c4909985

# ╟─0fbfed51-9df7-4e4f-b63b-354706ed297e
# ╠═9de8ddb3-2185-4846-b2b4-9199bd7a8fb9
# ╟─80bdb219-86bf-45f3-9409-3ccabb94bf26
# ╠═7e1f32a4-3f73-4d7a-bd43-978d5a3b48f2
# ╟─1391ee0a-bdc7-42a1-b3e4-e7fd521cf727
# ╠═7a957fb4-62a9-4db0-a633-8fa0ee4e13e2
# ╟─ed3a788c-ad86-49e7-b7b1-6a16e58edf1e
# ╠═7319b980-921b-490c-b4fc-91d52dfc3bd8
# ╟─ce9d24db-954e-43fe-816f-faf3940648a5
# ╟─9f78cb4d-5bef-4c12-b565-6be2a313f52c
# ╠═fb244c66-b97a-4c97-8fe5-8056033be405
# ╟─d2ba97de-01de-4029-8fae-afa845eab2dc
# ╠═82353f63-0302-4b6f-a4bd-304338a95032
# ╟─34faf338-5930-47f5-8c55-33797b0dd848
# ╠═0d6c6587-d3b4-460f-a802-f803372f334d
# ╟─5842dfba-0082-4577-a8b1-4a603ff6cdef
# ╠═3ef25b10-d59d-4ef0-9260-17d60d79297c
# ╟─8a707e3b-7987-4e48-acf6-994746282f00
# ╠═db98d90c-9b21-4de0-8c22-3572b3461b9b
# ╟─5a9cf26e-553e-482c-918a-c9845f1ec183
# ╠═f6f7bd9e-7354-4eea-8eb1-bfbabc1a5d13
# ╟─c0e1b0ee-1c1c-4b22-977f-844358b7f5fe
# ╟─3097376f-aad2-42f1-be36-122291ecb83b
# ╠═6a265d81-58c2-4d3c-9301-e576384c8b94
# ╟─2352442f-5289-4ae4-80ce-6c52292b4397
# ╟─33f103bd-d43b-4403-a1e7-ac963051a6c6
# ╟─b367f966-0d54-4824-b38f-fe78fac70748
# ╠═8217f156-4c1a-4a21-b7f7-46223b141649
# ╟─6ab51698-dfa2-48f2-b303-67cef7437585
# ╠═9bbbbd33-8405-4661-be46-e6efa8d47e3b
# ╟─d8e79b95-4920-4f68-bf77-8f4405110ae7
# ╠═2b96a551-eb7f-4a7e-a4d7-6d033640bd88
# ╟─1e2f1cc0-c886-4971-843d-b2620cce5ca3
# ╠═3ac314c7-8e05-4f96-ace0-0eae06b4940d
# ╟─291f0f6b-119e-401c-8cbf-238dcfd87f2e
# ╠═1d648ed3-1f29-4908-ae2a-b1b9daf150bd
# ╟─b1bb8b57-4281-46aa-bd5a-51b737115d34
# ╟─c9824e17-8438-4d11-9a8b-e1334a205062
# ╟─552d16a6-6bed-4487-86d3-8d67754e91b6
# ╟─e6a10885-305c-4666-984c-294cc36e44e9
# ╟─a453b406-4daf-429b-9cf2-66ddcc2f46d9
# ╟─99c643d8-4077-4cfb-ba3e-aeba29119238
# ╠═19b541cb-9840-4bac-b411-974f2a77bd10
# ╟─4abcf1fc-44e4-4ae9-8a4a-b62f841dbe19
# ╟─b93cd336-6967-442b-aa25-e079140e19f5
# ╟─15834063-da8b-4739-b617-fa014b7511b5
# ╟─410c2bfd-27e0-4ad7-8c7d-639e96d561cd
# ╟─253df189-1341-4928-8dc6-81c6091d9e76
# ╠═c6d9fbfa-5234-4515-ba81-631d5ebf8154
# ╟─aa741fce-7971-4251-8c25-a33a1906d197
# ╠═ed139a17-1b1b-436d-8fa2-3b68d596b6c0
# ╟─7e673373-0c1e-4e42-8409-0b86ec437dd6
# ╠═e508e8e7-7479-4d44-a508-a50fcf8891e6
# ╟─dda359c4-3289-4ff1-a406-7ff1581015e9
# ╠═3df22914-0f7d-4eef-944e-a00f7f56bd4c
# ╟─fd2067f4-7679-4a3d-9b64-23811930b4f9
# ╟─e2375f9a-0d6a-404b-8037-21f022963460
# ╟─241505fe-9d9a-410b-be23-fe8d58a6ec58
# ╟─2b096a03-1748-4455-8a3c-a063a29ffda1
# ╠═3bdcdb42-af44-4ce0-82a6-a2274c4f338a
# ╟─9ad97f28-0d39-4583-8015-2e9fec9b00f4
# ╠═71d61e53-d360-4792-bf2b-1c02780d9955
# ╠═f2722416-6db5-4ddc-8310-768d2549c73c
# ╟─cdd1ad99-80b7-4e19-a9d5-9d7b0d6f2f7e
# ╟─641ca24d-a1a8-4538-aa3c-b6f2f58494a6
# ╟─180cbe4a-fd61-4c90-883d-f83b79103ec6
# ╠═fa91bc13-cbbf-44db-91bf-0555ed0376b4
# ╟─572c5522-d4fe-42da-841a-449566099d04
# ╠═54eb8804-4887-4a58-bd9b-fcd9d5a4a633
# ╠═cf2d64bd-f191-488e-a13f-7be6bcaf729e
# ╟─f083b4e0-3371-48ed-8e21-bfc7dfc23a6b
# ╠═2190eef8-254d-440e-9728-042c09f71575
# ╟─3ec46373-2fdd-4bd1-8c97-7dba659cb773
# ╟─6b73f861-974b-4191-83fa-fcb05cc99a55
# ╟─fd33b892-a02f-4a42-95e3-e53ea233fb89
# ╟─7e0800a1-fdd7-4140-ab8f-bf6677d0a271
# ╟─17d50742-8407-4d3a-a491-3cbd8deea720
# ╟─7640a3e8-b0ee-46e8-af45-757228604036
# ╠═3cc80e2c-49af-4d63-90aa-d86b91bcce6e
# ╟─e3a60f67-2035-4ba2-acbd-3befb4b5101f
# ╠═95301630-fbe5-47df-a69c-b45d1c61e80a
# ╟─309411fa-35eb-4a80-b244-e06a8e74d472
# ╟─8902ec37-4fbc-4a94-b09b-da93227116b5
# ╠═9723dd49-4df8-4a50-92fd-c1ef0f46cc09
# ╟─d497944c-589d-46c4-8ffd-ec48234da8f7
# ╠═ce61bf03-9a5a-480e-a9ea-352cdda83d94
# ╟─e06e972c-1f19-4759-9776-d57cb99ff864
# ╠═74696ca3-8f3e-4129-9900-f4b38dc78309
# ╟─8c443adb-692b-4b55-9e6a-577817bbcda9
# ╠═52ded531-752b-4427-bdfe-6a414d2bd426
# ╟─1ceb7ca2-bb9a-4b70-b6ee-d6ec174c7b29
# ╠═765e89bd-8c45-4c7c-80c3-c6a36c5fcf85
# ╟─f143162c-f3e8-4450-b9fb-9768284bf7cb
# ╟─782b3bf5-54a8-4909-af98-2e344442a59f
# ╟─316413eb-4f9a-4c8f-99d1-b2d55ddc6720
# ╠═d5b2a7de-535b-41fd-a5d9-b9fb939f4eeb
# ╠═e3cba55b-1801-4437-a045-fb71da811d6c
# ╠═1f1852ac-b1b9-4f00-9b41-3c398bf2eda6
# ╟─d5765d9c-011f-4f84-8f36-56e9ec6ed1b1
# ╟─1e599ef8-9cc3-4d7b-a5bd-113394dc188e
# ╠═5f50413c-1932-4b11-aa1b-feaa3337d9fb
# ╟─333e4d90-1f58-41a3-b8d7-a694740ae138
# ╠═75b98e62-8a3e-43aa-8387-24389ef91428
# ╟─5a9d494e-bfae-4398-97ce-7fa5dc48b609
# ╟─53ee3204-fcac-44e4-874d-eccc2f2f1d23
# ╠═7d0f940c-fc0c-4e4f-8764-5bee609f1989
# ╟─b44da75e-9371-4ca9-a2d7-2c43954ae359
# ╠═4725eb44-79e8-4d0d-b1b3-d4b8de23e9bb
# ╟─dccdea07-f998-49b3-93ee-41216913d527
# ╟─955fb2dc-b11a-4f97-a841-f84aa45a7e0c
# ╠═16711214-f8e6-4b29-99d2-c01fd5cead92
# ╟─42d4af87-6a18-4a2a-8192-07fb221a03c9
# ╠═d258b346-169b-48d4-a2bb-f1219b211aa1
# ╟─c447e9a0-cf40-4a55-9513-e68faeb86d8a
# ╠═7d9a476b-2201-42be-92f4-3cc0deb03538
# ╟─984c358e-ec73-4f32-ae42-94b82b338029

# ╟─09646d1c-49ed-44ed-be41-108ae0c2634b
# ╟─fb43a7a0-b3ec-4787-b464-2a18b2386cb7
# ╟─bbf93e76-ede2-4847-9cf6-7872c3239784

# ╠═09646d1c-49ed-44ed-be41-108ae0c2634b
# ╠═1b77e663-3320-44b9-b50a-925be8482101
# ╠═f26d91ab-69a8-4dd7-b082-e3913fb1b1ce
# ╠═552bd461-e2e3-4fcb-b979-abb6c27328f6
# ╠═d5a3d006-1038-4154-b904-45e50a3e55bb
# ╠═93f4d25b-80fd-4a3a-b446-745ac1fcab73
# ╠═d3045ada-9eea-48d7-a65f-33cd29f6380b
# ╠═bff408b6-cd10-48d5-b162-644fefda90c8
# ╠═c427d044-e40e-4923-a31e-299e80535a9b
# ╠═26c649f1-6670-44a3-883c-865c869322a8
# ╠═e590b0ac-5e8c-4b26-bc4b-d576b372d721
# ╠═5efc73e2-12d9-43c7-a577-a59667f7044c
# ╠═833616e1-55bf-4719-aac0-8bbeaa88d9c2
# ╠═8126ed19-fd04-4787-8608-d23ba8236f26
# ╠═f097690d-9d60-415f-9150-de23e9e2eea3
# ╠═ec477bb8-41dd-4c38-bf84-bdac076fbee1
# ╠═31a86d14-c9da-4cb0-80bd-eddfd22cef60
# ╠═765ebfcb-710d-4198-b9c4-bb603141a901
# ╠═77342518-bfbc-4531-9993-9f64a0552b35

# ╟─34506416-a59a-450f-835b-72f0fbc6ce74
# ╟─62e65843-4d73-4a18-8c7d-707b1e66a2d4
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
