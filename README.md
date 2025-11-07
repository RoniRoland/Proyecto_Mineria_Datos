# Análisis de Minería de Datos - Estadísticas Hospitalarias Internas (Guatemala)

Este proyecto implementa tres algoritmos de minería de datos en R para analizar datos hospitalarios internos de Guatemala en el año 2024:

- **Apriori** para descubrir reglas de asociación.
- **FP-Growth** (usando `fim4r`) para validar y ampliar las asociaciones.
- **K-Means** para segmentar pacientes según edad, días de estancia y tipo de tratamiento.

> **Entorno probado:** Windows 11, R 4.3.3.

---

## 1. Objetivo del proyecto

El objetivo principal es identificar patrones y relaciones entre variables hospitalarias, así como segmentar pacientes según características clínicas. Los resultados apoyan la toma de decisiones en gestión hospitalaria, planificación de recursos y mejora de la eficiencia de atención.

---
## 2. Requisitos previos

### Software
- **R** versión 4.3.3 o superior
- (Opcional) **RStudio**

### Paquetes necesarios
Instala los siguientes paquetes:

```r
install.packages(c("arules", "readxl", "ggplot2"))
```

Para instalar **`fim4r`**, el paquete debe descargarse manualmente desde su sitio oficial:

1. Ir a [https://borgelt.net/fim4r.html](https://borgelt.net/fim4r.html)
2. Descargar el archivo `.tar.gz` correspondiente a tu sistema operativo.
3. Desde la consola de R o RTools, ejecutar el comando:
   ```bash
   R CMD INSTALL fim4r_<versión>.tar.gz
   ```
4. Una vez instalado correctamente, cargarlo en R con la libreria arules:
   ```r
   library(arules)
   ```

> En caso de error durante la instalación, asegúrate de tener configurado Rtools (Windows) o las herramientas de compilación en Linux/macOS.

### Set de datos
- El conjunto de datos de los servicios internos hospitalarios se pueden conseguir directamente en la pagina del INE (Instituto Nacional de Estadistica): [interna-2024-da](https://datos.ine.gob.gt/dataset/estadisticas-hospitalarias-servicios-internos).
> En la misma pagina del INE se encuentra el diccionario de definciones para entender el significado de cada columna del set de datos.

---

## 3. Estructura esperada del dataset

El archivo de entrada (`interna-2024-da.xlsx`) debe contener, al menos, las siguientes columnas (según el diccionario provisto):

| Variable        | Descripción (según diccionario) | Observaciones/Valores típicos |
|-----------------|----------------------------------|-------------------------------|
| **AÑO**         | Año del registro                 | Constante (ej. 2024); se elimina del análisis de reglas si no aporta variación. |
| **MES**         | Mes del registro                 | 1–12 (Enero–Diciembre). |
| **DIASESTAN**   | Días de estancia                 | Válidos: 1–98; **9999 = ignorado** (filtrar antes de graficar/clusterizar). |
| **SEXO**        | Sexo del paciente                | 1 = Hombre; 2 = Mujer. |
| **PPERTENENCIA**| Pueblo de pertenencia            | 1 = Maya; (otros códigos según diccionario: Garífuna, Xinka, Ladino/Mestizo, etc.). |
| **EDAD**        | Edad numérica                    | En **unidades indicadas por `PERIODOEDA`**. Para análisis se usa en años con rango 0–99. |
| **PERIODOEDA**  | Período de Edad (unidad)         | 1 = Días; 2 = Meses; 3 = Años; 9 = Ignorado. |
| **DEPTORESIDEN**| Departamento de residencia       | Códigos departamentales (p. ej. 1 = Guatemala). |
| **MUNIRESIDEN** | Municipio de residencia          | Códigos municipales (p. ej. 0101 = Guatemala). |
| **CAUFIN / Causa de atención** | Causa (diagnóstico) | Codificado en **CIE-10** (ver hoja *CIE-10* del diccionario). |
| **CONDIEGRES**  | Condición de egreso              | 1 = Vivo; (otros códigos según diccionario, p. ej. 2 = Fallecido). |
| **TRATARECIB**  | Tratamiento recibido             | 1 = Médico; (otros códigos según diccionario, p. ej. quirúrgico/obstétrico). |

> Nota: Los códigos exactos y etiquetas completas están en el archivo **diccionario-variables-interna.xlsx** (hoja *Interna* y *CIE-10*). Ajusta los mapeos de etiquetas en tus reportes si requieres nombres legibles.

-----------|--------------|
| **AÑO** | Año del registro (constante en 2024, se elimina del análisis) |
| **EDAD** | Edad del paciente (0–99 años) |
| **DIASESTAN** | Días de estancia hospitalaria (1–98 válidos, 9999 = ignorado) |
| **TRATARECIB** | Tipo de tratamiento recibido (1 a 3) |
| **PERIODOEDA** | Unidad de edad (1: Días, 2: Meses, 3: Años, 9: Ignorado) |

> Los valores fuera de rango (p. ej. 999 o 9999) representan datos **ignorados** y se filtran antes del clustering.

---

## 4. Ejecución del script

Ajusta la ruta del archivo Excel a tu entorno (usa `C:/` o `C\\` en Windows):

```r
library(arules)
library(readxl)
library(ggplot2)

# Leer datos
datos <- read_excel("C:/Users/tu_usuario/Documents/interna-2024-da.xlsx")

# Limpieza
datos_limpios <- subset(datos, select = -c(AÑO))
```

---

## 5. Algoritmos implementados

### **1. Apriori** (Reglas de asociación)

Busca combinaciones frecuentes entre variables hospitalarias.

```r
reglas <- apriori(datos_limpios, parameter = list(support=0.2, confidence=0.5))
inspect(reglas[1:1640])

df_reglas <- as(reglas, "data.frame")
```

**Interpretación:**
- *support* mide la frecuencia del patrón.
- *confidence* mide la probabilidad condicional.
- *lift* > 1 indica una asociación positiva significativa.

---

### **2. FP-Growth** (Validación de patrones)

Algoritmo alternativo más eficiente que Apriori.

```r
reglas_fp <- fim4r(datos_limpios, method = "fpgrowth", target = "rules", supp = 0.05, conf = 0.6)
rf <- as(reglas_fp, "data.frame")
head(rf)
```

**Ventaja:** evita generar combinaciones intermedias, acelerando el proceso sin perder precisión.

---

### **3. K-Means** (Clustering de pacientes)

Agrupa pacientes según similitud en edad, días de estancia y tratamiento.

```r
datos_cluster <- subset(datos_limpios,
                        EDAD >= 0 & EDAD <= 99 &
                        DIASESTAN >= 1 & DIASESTAN <= 98)

datos_cluster <- datos_cluster[, c("EDAD", "DIASESTAN", "TRATARECIB")]
datos_cluster[is.na(datos_cluster)] <- -1

cluster <- kmeans(datos_cluster, centers = 3)
```

**Visualización de clústeres:**

```r
ggplot(datos_cluster, aes(x = EDAD, y = DIASESTAN, color = as.factor(cluster$cluster))) +
  geom_point(alpha = 0.6) +
  geom_point(data = as.data.frame(cluster$centers), aes(x = EDAD, y = DIASESTAN),
             color = "black", size = 4, shape = 17) +
  scale_x_continuous(limits = c(0, 100)) +
  scale_y_continuous(limits = c(0, 100)) +
  labs(title = "Clústeres de Pacientes Hospitalarios (K-Means)",
       x = "Edad del Paciente (años)",
       y = "Días de Estancia Hospitalaria",
       color = "Clúster") +
  theme_minimal()
```

**Interpretación:**

| Clúster | Perfil | Descripción |
|-----------|---------|---------------|
| 1 | Jóvenes (0–20 años) | Estancias cortas, tratamientos simples. |
| 2 | Adultos mayores (50–100 años) | Estancias largas, tratamientos complejos. |
| 3 | Adultos (20–45 años) | Estancias intermedias, atención general. |

---

## 6. Resultados esperados

- **Apriori/FP-Growth:** patrones de residencia, edad y tratamiento que revelan concentraciones y tendencias en servicios hospitalarios.
- **K-Means:** tres perfiles clínicos de pacientes (pediátrico, adulto, adulto mayor) con relación directa entre edad y días de estancia.

---

## 7. Recomendaciones para replicar el entorno

### En Windows 11 (R 4.3.3)
1. Instala R desde [CRAN](https://cran.r-project.org/).
2. Abre RStudio y ejecuta:
   ```r
   install.packages(c("arules", "readxl", "ggplot2"))
   ```
3. Descarga e instala **fim4r** manualmente desde [https://borgelt.net/fim4r.html](https://borgelt.net/fim4r.html).
4. Ajusta la ruta del archivo `interna-2024-da.xlsx`.
5. Ejecuta el script completo.

### En Linux/macOS
- Reemplaza la ruta del archivo por `/home/usuario/.../dinterna-2024-da.xlsx` o `/Users/usuario/.../interna-2024-da.xlsx`.
- Asegúrate de tener las herramientas de compilación (Rtools o build-essential) para instalar `fim4r`.

---

## 8. Solución de errores comunes

| Error | Causa | Solución |
|--------|--------|-----------|
| `Error in discretizeDF` | Columna constante (ej. AÑO=2024) | Elimina columnas sin variación. |
| `No rules found` | Soporte/confianza demasiado altos | Reduce `supp` o `conf`. |
| Gráfico deformado | Valores extremos (9999) | Filtra `DIASESTAN <= 98`. |
| `fim4r no se instala` | Falta de binario o toolchain | Descarga manual desde borgelt.net y usa `R CMD INSTALL fim4r_<versión>.tar.gz`. |

---

## 9. Licencia y créditos

- **Autor:** Edgar Rolando Ramirez Lopez
- **Universidad:** Universidad San Carlos de Guatemala
- **Curso:** Minería de Datos
- **Licencia:** Uso académico libre.

---

### 📋 Versión del entorno
- Windows 11 (64 bits)
- R 4.3.3
- RStudio 2024.09+
- Paquetes: `arules 1.7+`, `fim4r 1.0+`, `ggplot2 3.5+`, `readxl 1.4+`

---

> ⚡ **Este proyecto demuestra la aplicación integrada de técnicas de minería de datos para la toma de decisiones en salud pública, enfocada en la optimización de recursos hospitalarios.**
