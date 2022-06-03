### A Pluto.jl notebook ###
# v0.19.5

using Markdown
using InteractiveUtils

# ╔═╡ e7ba903c-2752-4832-b69a-c93de0dd47ac
md"
# Descuentos Salario

Cálculo de los descuentos y deducciones de nómina aplicables a un salario en Colombia.
"

# ╔═╡ 370aa199-8df2-416b-996f-236075ff911e
# Dependencies
# TODO

# ╔═╡ 164c89b1-5284-401e-af21-103dade48b20
md"## Definiciones y Parámetros"

# ╔═╡ 32e16538-5cf0-4e06-85d7-b7a72841e5e3
begin
	const UVT = 38_004
	const SMMLV = 1_000_000
end;

# ╔═╡ 8e90c851-1aad-490b-b8f0-7ef60b15d111
begin
	salario     = 5_000_000
	no_salarial = 1_000_000
	dias_labor  = 30
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

	seguridad   = ibc.*[salud, pension, solidaridad]
	(sum(seguridad), seguridad)
end;

# ╔═╡ 4c2ca152-451e-47c4-9009-79f8067c6553
begin
	p  = salario + no_salarial
	nr = seguridad_social(ibc(salario, no_salarial))[1]
	rf = retencion_fuente(base_retencion(p, nr), dias_labor)
	(p, nr+rf)
end

# ╔═╡ Cell order:
# ╟─e7ba903c-2752-4832-b69a-c93de0dd47ac
# ╠═370aa199-8df2-416b-996f-236075ff911e
# ╟─164c89b1-5284-401e-af21-103dade48b20
# ╠═32e16538-5cf0-4e06-85d7-b7a72841e5e3
# ╠═8e90c851-1aad-490b-b8f0-7ef60b15d111
# ╠═4c2ca152-451e-47c4-9009-79f8067c6553
# ╠═2f935690-654c-46ce-aa80-6503069e1a19
# ╠═482e1467-3d98-49dc-94f9-15b52a8d30a8
# ╠═eee16024-c06c-4b79-9413-3542281079a2
# ╠═fda958ff-77b5-4849-ad02-84bbaa5badf2
# ╠═7854379f-602d-43e5-b4f4-02357028b139
# ╠═135a870d-655b-46c3-86f6-fbcc75e5267b
# ╟─361a4751-abd5-4c77-b514-dd8a13ebb50a
# ╠═202de137-96d9-4a01-b830-ec09b39d25e1
# ╠═bc1870e1-78dd-4c1c-b145-e99a88065a22
# ╠═51f742eb-d95e-4b23-b188-c3648e12bf65
