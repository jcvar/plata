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
	salario        = 5_000_000
	no_salarial    = 1_000_000
	días_laborados = 30
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
"

# ╔═╡ 482e1467-3d98-49dc-94f9-15b52a8d30a8
function ibc(s, ns)
	min(max(s, (s+ns)*0.6), 25*SMMLV)
end;

# ╔═╡ 361a4751-abd5-4c77-b514-dd8a13ebb50a
md"### Funciones de utilidad"

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
function seguridad_social(ibc)
	salud       = 0.04
	pension     = 0.04
	solidaridad = solidaridad_pensional(ibc)

	seguridad   = ibc.*[salud, pension,solidaridad]
	(sum(seguridad), seguridad)
end;

# ╔═╡ e1eb6268-2315-45c0-bf96-44208a1134fa
seguridad_social(ibc(salario*1.05, no_salarial))

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.3"
manifest_format = "2.0"

[deps]
"""

# ╔═╡ Cell order:
# ╟─e7ba903c-2752-4832-b69a-c93de0dd47ac
# ╠═370aa199-8df2-416b-996f-236075ff911e
# ╟─164c89b1-5284-401e-af21-103dade48b20
# ╠═32e16538-5cf0-4e06-85d7-b7a72841e5e3
# ╠═8e90c851-1aad-490b-b8f0-7ef60b15d111
# ╠═2f935690-654c-46ce-aa80-6503069e1a19
# ╠═482e1467-3d98-49dc-94f9-15b52a8d30a8
# ╠═eee16024-c06c-4b79-9413-3542281079a2
# ╠═e1eb6268-2315-45c0-bf96-44208a1134fa
# ╟─361a4751-abd5-4c77-b514-dd8a13ebb50a
# ╠═51f742eb-d95e-4b23-b188-c3648e12bf65
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
