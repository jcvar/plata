### A Pluto.jl notebook ###
# v0.19.5

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

# ╔═╡ 370aa199-8df2-416b-996f-236075ff911e
using PlutoUI, CSV
# TODO

# ╔═╡ e7ba903c-2752-4832-b69a-c93de0dd47ac
md"
# Descuentos Salario

Cálculo de los descuentos y deducciones de nómina aplicables a un salario en Colombia.

El objetivo de esta herramienta es generar un resumen de ingresos y descuentos anual, que puede ser exportado en un formato amigable.
"

# ╔═╡ e33d94b5-77ea-4a99-8859-ec92fa3c0611
md"## tl;dr

Se pueden obtener las deducciones sobre un salario de así:

```
nomina_mes = mes(salario, no_sal, exento, deduccion, dias)
```
Donde:

- `salario`: el salario base del trabajador
- `no_sal`: el ingreso no salarial del trabajador
- `exento`: posibles rentas exentas
- `deduccion`: posibles deducciones a la base gravable
- `dias`: número de días laborados en el mes (opcional)
"

# ╔═╡ 4a51f317-64df-4b6d-9341-5ea872917cfc
md"## Importar y Exportar"

# ╔═╡ 89c56520-3ea2-4e80-8562-277a4a4253eb
@bind data_salarial FilePicker()

# ╔═╡ b5d31661-8a6e-40c0-a568-7d5f2c8b21de
data = CSV.File(data_salarial["data"])

# ╔═╡ 164c89b1-5284-401e-af21-103dade48b20
md"## Definiciones"

# ╔═╡ 32e16538-5cf0-4e06-85d7-b7a72841e5e3
begin
	# const UVT = 36_308 # 2021
	const UVT = 38_004 # 2022
	const SMMLV = 1_000_000
end;

# ╔═╡ 2f935690-654c-46ce-aa80-6503069e1a19
md"## Seguridad social
Un trabajador debe estar afiliado al sistema de salud y al sistema de pensiones.

| Concepto             | Empleador       | Trabajador | Total           |
|:---------------------|-----------------|------------|-----------------|
| Salud                | 8.5%            | 4%         | 12.5%           |
| Pensión              | 12%             | 4%         | 16%             |

Adicionalmente, aquellos trabajadores que devenguen un salario igual o mayor a 4 SMMLV deben realizar un aporte adicional al sistema de pensiones.

Como parte de la seguridad social se encuentra el aporte a Riesgos Laborales, que en el caso de los trabajadores dependientes, es asumido en su totalidad por el empleador.
El aporte es de 0.522% a 6.960%, dependiendo del nivel de riesgo del trabajador.


### Ingreso Base de Cotización
Ley 1393 de 2010, Artículo 30:
> ARTÍCULO  30. Sin perjuicio de lo previsto para otros fines, para los efectos relacionados con los artículos 18 y 204 de la Ley 100 de 1993, los pagos laborales no constitutivos de salario de las trabajadores particulares no podrán ser superiores al 40% del total de la remuneración.

Ley 100 de 1993, Artículo 18, modificado por la Ley 797 del 2003, Artículo 5:
> El límite de la base de cotización será de veinticinco (25) salarios mínimos legales mensuales vigentes para trabajadores del sector público y privado.

Este límite de 25 SMMLV se aplica sin importar el número de días correspondientes al pago.
"

# ╔═╡ 482e1467-3d98-49dc-94f9-15b52a8d30a8
"""
Calcula el Ingreso Base de Cotización dados los ingresos salariales y
no salariales del mes, hasta un máximo de 25 SMMLV.

Ley 1393 de 2010, Artículo 30
Ley 100 de 1993, Artículo 18
"""
ibc(s, ns) = min(max(s, 0.6 * (s + ns)), 25 * SMMLV);

# ╔═╡ fda958ff-77b5-4849-ad02-84bbaa5badf2
md"
## Retención en la Fuente por Salarios.
La retención en la fuente es un cobro anticipado del impuesto de renta que deben realizar todas las personas naturales o jurídicas que realicen pagos laborales.

Al igual que el impuesto de renta, la retención en la fuente se aplica de manera progresiva de acuerdo a la base sujeta a retención.

El Estatuto Tributario define dos procedimientos para realizar la retención en la fuente a un salario. El procedimiento 1 es aplicable al salario de un mes dado mientras que en el procedimiento 2, semestralmente se establece un porcentaje fijo para la retención, de acuerdo a las retenciones aplicadas durante los anteriores 12 meses. Solamente se explicará el procedimiento 1.

La base de retención se determina de la siguiente manera:
Pagos laborales, menos ingresos no constitutivos de renta, menos rentas exentas, menos deducciones, menos renta de trabajo exenta (25%)

La normativa establece diferentes límites a los elementos que conforman cada una de las categorías mencionadas anteriormente, y de manera general, el numeral 2 del artículo 388 del Estatuto Tributario indica:
> En todo caso, la suma total de deducciones y rentas exentas no podrá superar el cuarenta por ciento (40%) del resultado de restar del monto del pago o abono en cuenta los ingresos no constitutivos de renta ni ganancia ocasional imputables.

Una vez se ha calculado la base de retención, se toma su valor en UVT y se calcula la retención en la fuente de acuerdo a la siguiente tabla (Artículo 383 del Estatuto Tributario):

| Desde |       Hasta | Tarifa Marginal | Impuesto                                                                  |
|------:|------------:|----------------:|---------------------------------------------------------------------------|
|    >0 |          95 |              0% | 0                                                                         |
|   >95 |         150 |             19% | (Ingreso laboral gravado expresado en UVT menos 95 UVT)*19%               |
|  >150 |         360 |             28% | (Ingreso laboral gravado expresado en UVT menos 150 UVT)*28% más 10 UVT   |
|  >360 |         640 |             33% | (Ingreso laboral gravado expresado en UVT menos 360 UVT)*33% más 69 UVT   |
|  >640 |         945 |             35% | (Ingreso laboral gravado expresado en UVT menos 640 UVT)*35% más 162 UVT  |
|  >945 |        2300 |             37% | (Ingreso laboral gravado expresado en UVT menos 945 UVT)*37% más 268 UVT  |
| >2300 | En adelante |             39% | (Ingreso laboral gravado expresado en UVT menos 2300 UVT)*39% más 770 UVT |

Se redondea a miles pesos.
"

# ╔═╡ 7854379f-602d-43e5-b4f4-02357028b139
"""
Calcula la base de retención en la fuente
"""
function base_retencion(pagos, no_renta, renta_exenta = 0, deducciones = 0)
	gravable   = pagos - no_renta
	descuentos = renta_exenta + deducciones
	gravable - min(descuentos + 0.25 * (gravable - descuentos), 0.4 * gravable)
end;

# ╔═╡ 74cfab4a-fd89-4075-b7b6-99bfea9c34d2
md"## Cálculo

Utilizando lo explicado anteriormente, podemos calcular la nómina del mes de acuerdo a los parámetros requeridos"

# ╔═╡ ef5973cc-acad-4b0c-9311-8f5afc29fad6
struct Nomina
	salario::Int
	no_salarial::Int
	retefuente::Int
	salud::Int
	pensión::Int
	solidaridad::Int
	devengado::Int
	descuento::Int
	total::Int
end

# ╔═╡ 361a4751-abd5-4c77-b514-dd8a13ebb50a
md"### Funciones auxiliares"

# ╔═╡ 202de137-96d9-4a01-b830-ec09b39d25e1
pesos(uvt) = uvt * UVT; # Convierte UVTs a pesos

# ╔═╡ bc1870e1-78dd-4c1c-b145-e99a88065a22
uvt(pesos) = pesos / UVT; # Convierte pesos a UVT

# ╔═╡ 135a870d-655b-46c3-86f6-fbcc75e5267b
"""
Calcula la retención en la fuente en pesos de acuerdo a la base de retención en pesos y el número de días laborados.
"""
function retencion_fuente(base, d=30)
	rango   = [2300,  945,  640,  360,  150,   95, 0]
	tasa    = [0.39, 0.37, 0.35, 0.33, 0.28, 0.19, 0]
	uvt_add = [ 770,  268,  162,   69,   10,    0, 0]

	base_uvt = uvt(base) * (30 / d)
	for (r, t, u) in zip(rango, tasa, uvt_add)
		if base_uvt > r
			ret_uvt = ((base_uvt - r) * t + u) * (d / 30)
			return round(pesos(ret_uvt), digits= -3)
		end
	end
end;

# ╔═╡ 51f742eb-d95e-4b23-b188-c3648e12bf65
"""
Calcula el porcentaje adicional correspondiente a solidaridad pensional.
(Toma el límite inferior de todos los rangos como estríctamente mayor)

SMMLVs	 => %
( 0,  4) => 0.0%
[ 4, 16) => 1.0%
[16, 17] => 1.2%
(17, 18] => 1.4%
(18, 19] => 1.6%
(19, 20] => 1.8%
(20,     => 2.0%

Ley 100 de 1993, Artículo 27
Decreto 1833 de 2016, Artículo 2.2.3.1.9
"""
function solidaridad_pensional(s)
	rango      = [   20,    19,    18,    17,    16,     4, 0]
	porcentaje = [0.020, 0.018, 0.016, 0.014, 0.012, 0.010, 0]
	s_smmlv    = s/SMMLV

	for (r, p) in zip(rango, porcentaje)
		if s_smmlv > r
			return p
		end
	end
end;

# ╔═╡ eee16024-c06c-4b79-9413-3542281079a2
"""
Calcula los aportes a seguridad social de acuerdo al IBC dado.

Retorna una tupla donde el primer elemento es el total de los aportes en ese periodo, y el segundo será un vector con los pagos correspondientes a salud, pensión y solidaridad pensional.
"""
function seguridad_social(ibc)
	salud       = 0.04
	pension     = 0.04
	solidaridad = solidaridad_pensional(ibc)

	ibc.*[salud, pension, solidaridad]
end;

# ╔═╡ ef1ff529-7cfc-4086-8ad7-f5cfbecf7603
"""
Calcula la nómina del mes de acuerdo al salario, ingresos no salariales, rentas exentas, deducciones y días laborados.
"""
function mes(sal, no_sal, exe, ded, d = 30)
	sm = sal*(d/30)
	ss = seguridad_social(ibc(sm, no_sal))

	dev = sm + no_sal
	rf = retencion_fuente(base_retencion(dev, sum(ss), exe, ded), d)
	des = rf + round.(sum(ss)) + ded

	Nomina(sm, no_sal, rf, round.(ss)..., dev, des, dev - des)
end;

# ╔═╡ 1d85fd9a-264f-4366-84d3-6ca33ebb2177
mes(5_000_000, 1_000_000, 0, 0)

# ╔═╡ d5a70593-e381-4707-8d5e-cd680cb74b1f
m = map(row -> mes(row...), data)

# ╔═╡ d06c9a69-011f-45b9-89f9-d5d5535ac7af
dl = let io = IOBuffer()
	CSV.write(io, m)
	take!(io)
end

# ╔═╡ ed4b0997-9fe8-41ce-839d-0a575379a5b6
DownloadButton(dl, "dl.csv")

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
CSV = "~0.10.4"
PlutoUI = "~0.7.39"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.3"
manifest_format = "2.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings"]
git-tree-sha1 = "873fb188a4b9d76549b81465b1f75c82aaf59238"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.4"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "0f4e115f6f34bbe43c19751c90a38b2f380637b9"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.3"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "9be8be1d8a6f44b96482c8af52238ea7987da3e3"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.45.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.DataAPI]]
git-tree-sha1 = "fb5f5316dd3fd4c5e7c30a24d50643b73e37cd40"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.10.0"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "129b104185df66e408edd6625d480b7f9e9823a0"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.18"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "61feba885fac3a407465726d0c330b3055df897f"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.1.2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "1285416549ccfcdf0c50d4997a94331e88d68413"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.3.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "8d1f54886b9037091edf146b517989fc4a09efec"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.39"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "db8481cf5d6278a121184809e9eb1628943c7704"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.13"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╠═370aa199-8df2-416b-996f-236075ff911e
# ╟─e7ba903c-2752-4832-b69a-c93de0dd47ac
# ╟─e33d94b5-77ea-4a99-8859-ec92fa3c0611
# ╠═1d85fd9a-264f-4366-84d3-6ca33ebb2177
# ╟─4a51f317-64df-4b6d-9341-5ea872917cfc
# ╠═89c56520-3ea2-4e80-8562-277a4a4253eb
# ╠═ed4b0997-9fe8-41ce-839d-0a575379a5b6
# ╠═b5d31661-8a6e-40c0-a568-7d5f2c8b21de
# ╠═d5a70593-e381-4707-8d5e-cd680cb74b1f
# ╠═d06c9a69-011f-45b9-89f9-d5d5535ac7af
# ╟─164c89b1-5284-401e-af21-103dade48b20
# ╠═32e16538-5cf0-4e06-85d7-b7a72841e5e3
# ╟─2f935690-654c-46ce-aa80-6503069e1a19
# ╠═482e1467-3d98-49dc-94f9-15b52a8d30a8
# ╠═eee16024-c06c-4b79-9413-3542281079a2
# ╟─fda958ff-77b5-4849-ad02-84bbaa5badf2
# ╠═7854379f-602d-43e5-b4f4-02357028b139
# ╠═135a870d-655b-46c3-86f6-fbcc75e5267b
# ╟─74cfab4a-fd89-4075-b7b6-99bfea9c34d2
# ╠═ef5973cc-acad-4b0c-9311-8f5afc29fad6
# ╠═ef1ff529-7cfc-4086-8ad7-f5cfbecf7603
# ╟─361a4751-abd5-4c77-b514-dd8a13ebb50a
# ╠═202de137-96d9-4a01-b830-ec09b39d25e1
# ╠═bc1870e1-78dd-4c1c-b145-e99a88065a22
# ╠═51f742eb-d95e-4b23-b188-c3648e12bf65
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
