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

datos_cluster <- subset(datos_limpios,
                        EDAD >= 0 & EDAD <= 99 &
                          DIASESTAN >= 1 & DIASESTAN <= 98)

datos_cluster <- datos_cluster[, c("EDAD", "DIASESTAN", "TRATARECIB")]

datos_cluster[is.na(datos_cluster)] <- -1


cluster <- kmeans(datos_cluster, centers = 3)


ggplot(datos_cluster, aes(x = EDAD, y = DIASESTAN, color = as.factor(cluster$cluster))) +
  geom_point() +
  geom_point(
    data = as.data.frame(cluster$centers),
    aes(x = EDAD, y = DIASESTAN),
    color = "black", size = 4, shape = 17
  ) +
  labs(
    title = "Clústeres de Pacientes Hospitalarios (K-Means)",
    x = "Edad del Paciente",
    y = "Días de Estancia Hospitalaria",
    color = "Clúster"
  ) +
  theme_minimal()
