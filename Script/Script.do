* -*- coding: UTF-8 -*- 
* -------------------------------------------------------------------
* Script Name: Analisis_Contribuciones_Experimentos.do
* Creation Date: 2025-09-23
* Author: Sofia Obando, Juan David Vargas, Alejandro Herrera
* Description:
*   Este script en Stata analiza datos de dos fuentes experimentales 
*   dentro del Taller 4 de Economía Experimental:
*
*   1) Base "juego20252_haciendo_econ.xlsx":
*      - Datos generados en el aula sobre contribuciones en un juego.
*      - Incluye importación desde Excel, limpieza de variables
*        y cálculo de contribuciones promedio por ronda.
*      - Se generan gráficos de evolución de la cooperación.
*
*   2) Base "doing-economics-datafile-working-in-excel-project-2.xlsx":
*      - Datos del experimento de Herrmann, Thöni y Gächter (2008),
*        con tratamiento "con castigo" y "sin castigo".
*      - Se realiza análisis descriptivo de medias, varianzas, 
*        mínimos, máximos y comparación de periodos 1 y 10.
*      - Se generan gráficos comparativos (líneas y barras).
*
*   El objetivo es contrastar los resultados del juego en clase 
*   con los patrones descritos en los experimentos internacionales,
*   explorando la dinámica de cooperación, el free-riding y 
*   el efecto del castigo sobre las contribuciones.
*
*   El análisis incluye:
*     - Importación de datos desde Excel (.xlsx)
*     - Renombramiento y conversión de variables (contribución, ronda)
*     - Limpieza de datos (relleno de rondas faltantes, exclusión de NA)
*     - Cálculo de la contribución promedio por período (ronda)
*     - Visualización mediante:
*         • Gráfico de línea de la contribución promedio por ronda
*         • Gráficos comparativos en rondas iniciales y finales
*
* Notes:
*   - Ajustar la ruta de los archivos Excel antes de ejecutar.
*   - Los valores faltantes se excluyen de los cálculos.
*   - Los gráficos se muestran en la ventana de resultados de Stata.
*
* References:
*   Taller 4 – Experimentos ES :contentReference[oaicite:0]{index=0}
*   Herrmann, B., Thöni, C., & Gächter, S. (2008).
*     "Antisocial punishment across societies." Science, 319(5868), 1362–1367.
*   Archivos: 
*     - juego20252_haciendo_econ.xlsx 
*     - doing-economics-datafile-working-in-excel-project-2.xlsx
* -------------------------------------------------------------------

clear all

*-------------------------------------------------------------------------------
*2.1.1
*-------------------------------------------------------------------------------

* 1) Importar datos y forzar nombres válidos
import excel "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Raw\juego20252 haciendo econ.xlsx", ///
    sheet("Hoja1") firstrow clear 

* 2) Revisar nombres de variables
describe

* (asumamos que Stata puso "Players_contributions" como nombre)
rename Playerscontri~s  contribucion

* 3) Quitar el símbolo de moneda y convertir a numérico
destring contribucion, replace ignore("€")

* Hacemos lo mismo para los payoffs si los quieres usar luego
rename Payoffsinthis~e payoff
destring payoff, replace ignore("€")

* 4) Rellenar valores faltantes en Round (cuando sólo aparece en la primera fila)
replace Round = Round[_n-1] if missing(Round)

* Asegurar que Round sea numérico
destring Round, replace force

* 5) Calcular contribución promedio por periodo
collapse (mean) contribucion_promedio = contribucion, by(Round)

* 6) Graficar
twoway line contribucion_promedio Round, ///
    xtitle("Período") ytitle("Contribución promedio") ///
    title("Contribución promedio por período") lcolor(yellow)

graph export "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Outputs\Images\contribuciones_promedio_por_periodo.png", as(png) replace



*******************
*2.2 (Herrmann, Thöni & Gächter, 2008)
*******************


* Datos sin castigo (filas 2–12)
import excel "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Raw\doing-economics-datafile-working-in-excel-project-2", sheet("Public goods contributions") cellrange(A2:Q12) firstrow clear

gen tratamiento = "Sin castigo"
tempfile sin
save `sin'

* Datos con castigo (filas 16–26)
import excel "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Raw\doing-economics-datafile-working-in-excel-project-2", sheet("Public goods contributions") cellrange(A16:Q26) firstrow clear
gen tratamiento = "Con castigo"
tempfile con
save `con'

* Unir datasets
use `sin', clear
append using `con'

* Guardar nuevo dataset
save "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Created\append.dta", replace

export excel using "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Created\append.xlsx", firstrow(variables) replace

* -----------------------------------------------------
* 2.2.1 – PROMEDIOS POR PERIODO Y GRAFICO DE LINEAS
* -----------------------------------------------------
use "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Created\append.dta", clear

* Calcular la contribución promedio de cada fila (todas las ciudades)
egen promedio = rowmean(Copenhagen Dnipropetrovsk Minsk StGallen Muscat Samara ///
                        Zurich Boston Bonn Chengdu Seoul Riyadh Nottingham ///
                        Athens Istanbul Melbourne)

* Colapsar datos: promedio por Periodo y tratamiento
collapse (mean) promedio, by(Period tratamiento)

twoway (line promedio Period if tratamiento=="Sin castigo", lcolor(purple) lwidth(medthick) msymbol(circle)) ///
       (line promedio Period if tratamiento=="Con castigo", lcolor(green) lwidth(medthick) msymbol(circle)), ///
       title("Contribuciones promedio por período") ///
       xtitle("Período (1–10)") ytitle("Contribución promedio") ///
       xlabel(1(1)10) ylabel(4(1)14) legend(order(1 "Sin castigo" 2 "Con castigo") pos(6))
       
* Guardar imagen

graph export "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Outputs\Images\contribuciones_promedio.png", as(png) replace

* ------------------------------------------------------------------------------------
* 2.2.2 – GRAFICO DE BARRAS (PERIODO 1 vs 10)
* -------------------------------------------------------------------------------------

* Filtrar solo primer y último período
keep if Period==1 | Period==10

graph bar promedio, over(tratamiento, gap(0)) over(Period, gap(10) relabel(1 "1" 2 "10")) asyvars ///
    bar(1, bcolor(purple)) bar(2, bcolor(green)) ///
    blabel(bar, position(outside) format(%4.1f)) ///
    ytitle("Contribución promedio") ///
    title("Comparación entre primer y último período") ///
    legend(order(2 "Sin castigo" 1 "Con castigo"))
	
graph export "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Outputs\Images\Comparación entre primer y último período.png", as(png) replace

* -----------------------------------------------------
* 2.2.3 y 2.2.4 – ESTADISTICAS DESCRIPTIVAS
* -----------------------------------------------------
clear all

use "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Created\append.dta", clear

* 1. Crear primer bloque con una ciudad
preserve
keep tratamiento Copenhagen
rename Copenhagen valor
gen ciudad = "Copenhagen"
save largo_tot, replace
restore

* 2. Ir añadiendo las demás ciudades
foreach c in Dnipropetrovsk Minsk StGallen Muscat Samara Zurich Boston Bonn Chengdu Seoul Riyadh Nottingham Athens Istanbul Melbourne {
    preserve
    keep tratamiento `c'
    rename `c' valor
    gen ciudad = "`c'"
    append using largo_tot
    save largo_tot, replace
    restore
}

* 3. Abrir el dataset final
use largo_tot, clear

*4 Crear variable periodo que se numere de 1 a 10 y luego reinicie
gen periodo = mod(_n-1,10) + 1

*Guardar bases

export excel using "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Created\largo_tot.xlsx", firstrow(variables) replace

save "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Created\largo_tot.dta", replace

use "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Created\largo_tot.dta", clear

* Calcular estadísticas descriptivas por período y tratamiento
foreach p in 1 10 {
    di "-----------------------------------"
    di "Periodo `p'"
    foreach t in "Sin castigo" "Con castigo" {
        preserve
        keep if periodo==`p' & tratamiento=="`t'"
        quietly su valor
        di "`t': Media=" %6.2f r(mean) ///
            "  SD=" %6.2f r(sd) ///
            "  Min=" %6.2f r(min) ///
            "  Max=" %6.2f r(max)
        restore
    }
}






*-----------------------------------------------------------------------------------------
*P2.3.2
*-----------------------------------------------------------------------------------------

use "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Created\append.dta", clear

* Filtrar Período 1
keep if Period == 1

* 1. Crear primer bloque con una ciudad
preserve
keep tratamiento Copenhagen
rename Copenhagen valor
gen ciudad = "Copenhagen"
save largo, replace
restore

* 2. Ir añadiendo las demás ciudades
foreach c in Dnipropetrovsk Minsk StGallen Muscat Samara Zurich Boston Bonn Chengdu Seoul Riyadh Nottingham Athens Istanbul Melbourne {
    preserve
    keep tratamiento `c'
    rename `c' valor
    gen ciudad = "`c'"
    append using largo
    save largo, replace
    restore
}

* 3. Abrir el dataset final
use largo, clear

*Guardar bases
export excel using "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Created\largo.xlsx", firstrow(variables) replace

save "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Created\largo.dta", replace

* 4. Ejecutar el t-test
ttest valor, by(tratamiento)


********************************************************************************
*P2.3.3
********************************************************************************
clear all

use "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Created\append.dta", clear

* 1. Filtrar solo el Período 10
keep if Period == 10

* 2. Crear primer bloque con una ciudad
preserve
keep tratamiento Copenhagen
rename Copenhagen valor
gen ciudad = "Copenhagen"
save largo10, replace
restore

* 3. Ir añadiendo las demás ciudades
foreach c in Dnipropetrovsk Minsk StGallen Muscat Samara Zurich Boston Bonn Chengdu Seoul Riyadh Nottingham Athens Istanbul Melbourne {
    preserve
    keep tratamiento `c'
    rename `c' valor
    gen ciudad = "`c'"
    append using largo10
    save largo10, replace
    restore
}

* 4. Abrir el dataset final para el período 10
use largo10, clear

export excel using "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Created\largo10.xlsx", firstrow(variables) replace

save "C:\Users\Lenovo\Documents\2025\2025-2\Haciendo Economía\Taller 4\Created\largo10.dta", replace

* 5. Ejecutar el t-test
ttest valor, by(tratamiento)

* (Opcional) descriptivos
tabstat valor, by(tratamiento) stats(mean sd n)


















