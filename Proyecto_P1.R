library(arules)
library(readxl)

datos <- read_excel("F:\\Documentos\\Docs Roni\\Documentos Roni\\Docs U AND Cursos\\USAC MAESTRIA\\MAESTRIA DATA ANLISIS\\Cursos\\Mineria de datos\\Proyecto\\interna-2024-da.xlsx")

datos_limpios <- subset(datos, select = -c(AÑO))

reglas <- apriori(datos_limpios, parameter = list(support=0.2, confidence=0.5))

inspect(reglas[0:1640])

df_reglas <- as(reglas, "data.frame")

reglas_fp <- fim4r(datos_limpios, method = "fpgrowth", target = "rules", supp = 0.05, conf = 0.6)

rf <- as(reglas_fp, "data.frame")

head(rf)
