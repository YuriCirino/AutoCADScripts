# CAD Parallel Line Selector (AutoLISP)

Ferramenta em AutoLISP para seleção inteligente de linhas e polylines paralelas em desenhos do AutoCAD, especialmente útil para arquivos importados de PDF (ex: projetos de SPDA).

---

## 🚀 Problema que resolve

Ao importar PDFs para o AutoCAD:

- Linhas tracejadas viram múltiplos segmentos
- Letras e símbolos viram polylines irregulares
- Geometria fica "suja" e difícil de manipular

Este script resolve isso permitindo:

✅ Selecionar automaticamente elementos paralelos  
✅ Filtrar polylines que NÃO são retas  
✅ Ignorar ruído geométrico (letras, símbolos, etc)  
✅ Trabalhar com tolerâncias configuráveis  

## 🧠 Como funciona

O algoritmo usa 3 critérios principais:

### 1. Paralelismo (ângulo)
- Calcula o ângulo da entidade base
- Compara com outras entidades
- Usa tolerância angular (em graus)


### 2. Comprimento (relativo)
- Compara com base percentual
- Ex: 5% de tolerância


### 3. Alinhamento (eixo X/Y)
- Usa o centro da entidade
- Compensa erros de importação de PDF

### 4. Validação de polyline (🔥 diferencial)

Antes de considerar uma polyline:

- Analisa TODOS os segmentos internos
- Se algum segmento fugir da direção → descarta

👉 Isso elimina:
- Letras
- Símbolos
- Ruído de PDF

---

## ⚙️ Parâmetros

Ao executar o comando:

```text
SELSEMELHANTES
```
Você define:
- Tolerância de comprimento (%)
- Tolerância de alinhamento (unidades do desenho)
- Tolerância angular (graus)

📌 Exemplo recomendado (SPDA)
- Comprimento: 5%
- Alinhamento: 10 a 20
- Ângulo: 0.5° a 1°
- 🧪 Fluxo de uso
1. Carregar o LISP: 
2. Executar
3. Selecionar uma linha base
4. Ajustar tolerâncias
5. Resultado: seleção automática das entidades semelhantes

🏗️ Estrutura do algoritmo
Etapas:
1. Seleção da entidade base
2. Extração de:
 - Comprimento
 - Ângulo
 - Centro
3. Varredura do desenho
4. Filtros:
 - Tipo (LINE / LWPOLYLINE)
 - Retidão da polyline
 - Paralelismo
 - Comprimento
 - Alinhamento
5. Seleção final
