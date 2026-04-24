(defun isPolylineReta (obj tolAng / pts i p1 p2 ang angBase angDiff isReta)

  (setq pts (vlax-get obj 'Coordinates))

  ;; se tiver só 1 segmento → é reta
  (if (< (/ (length pts) 2) 3)
    T
    (progn
      (setq isReta T)

      ;; primeiro segmento define base
      (setq p1 (list (nth 0 pts) (nth 1 pts)))
      (setq p2 (list (nth 2 pts) (nth 3 pts)))
      (setq angBase (angle p1 p2))

      (setq i 2)

      (while (and isReta (< i (- (length pts) 2)))

        (setq p1 (list (nth i pts) (nth (+ i 1) pts)))
        (setq p2 (list (nth (+ i 2) pts) (nth (+ i 3) pts)))

        (setq ang (angle p1 p2))

        ;; diferença angular
        (setq angDiff (abs (- ang angBase)))

        ;; normalização
        (if (> angDiff pi)
          (setq angDiff (- (* 2 pi) angDiff))
        )

        (if (> angDiff (/ pi 2))
          (setq angDiff (- pi angDiff))
        )

        ;; se algum segmento fugir → marca como NÃO reta
        (if (> angDiff tolAng)
          (setq isReta nil)
        )

        (setq i (+ i 2))
      )

      isReta
    )
  )
)

(defun c:SELSEMELHANTES ( / ent data tipo obj
                            p1 p2 len ang eixoVal
                            tolLen tolAxis tolAng
                            ss i e data2 tipo2 obj2
                            p1b p2b lenb angb eixoValb
                            angDiff ssOut)

  (vl-load-com)

  ;; =========================
  ;; SELECIONAR OBJETO BASE
  ;; =========================
  (setq ent (car (entsel "\nSelecione uma linha ou polyline base: ")))

  (if (not ent)
    (progn (prompt "\nNada selecionado.") (exit))
  )

  (setq data (entget ent))
  (setq tipo (cdr (assoc 0 data)))

  ;; =========================
  ;; GEOMETRIA BASE
  ;; =========================
  (cond
    ((= tipo "LINE")
      (setq p1 (cdr (assoc 10 data)))
      (setq p2 (cdr (assoc 11 data)))
      (setq len (distance p1 p2))
    )

    ((= tipo "LWPOLYLINE")
      (setq obj (vlax-ename->vla-object ent))

      ;; validar se é reta
      (setq tolAngTemp (/ (* 1.0 pi) 180.0)) ;; 1 grau padrão
      (if (not (isPolylineReta obj tolAngTemp))
        (progn
          (prompt "\nPolyline base não é reta.")
          (exit)
        )
      )

      (setq p1 (vlax-curve-getStartPoint obj))
      (setq p2 (vlax-curve-getEndPoint obj))
      (setq len (vlax-curve-getDistAtParam obj
                   (vlax-curve-getEndParam obj)))
    )

    (T
      (prompt "\nTipo não suportado.")
      (exit)
    )
  )

  ;; Ângulo base
  (setq ang (angle p1 p2))
  (if (< ang 0) (setq ang (+ ang (* 2 pi))))

  ;; Centro (melhor que usar p1)
  (if (or (< (abs ang) 0.1) (< (abs (- ang pi)) 0.1))
    (setq eixoVal (/ (+ (cadr p1) (cadr p2)) 2.0))
    (setq eixoVal (/ (+ (car p1) (car p2)) 2.0))
  )

  ;; =========================
  ;; TOLERÂNCIAS
  ;; =========================
  (setq tolLen (getreal "\nTolerância de comprimento (%) <5>: "))
  (if (null tolLen) (setq tolLen 5.0))
  (setq tolLen (/ tolLen 100.0))

  (setq tolAxis (getreal "\nTolerância de alinhamento <10.0>: "))
  (if (null tolAxis) (setq tolAxis 10.0))

  (setq tolAng (getreal "\nTolerância angular (graus) <1.0>: "))
  (if (null tolAng) (setq tolAng 1.0))
  (setq tolAng (/ (* tolAng pi) 180.0))

  ;; =========================
  ;; BUSCAR ENTIDADES
  ;; =========================
  (setq ss (ssget "_X" '((0 . "LINE,LWPOLYLINE"))))

  (if (not ss)
    (progn
      (prompt "\nNenhuma entidade encontrada.")
      (exit)
    )
  )

  (setq ssOut (ssadd))
  (setq i 0)

  ;; =========================
  ;; LOOP PRINCIPAL
  ;; =========================
  (while (< i (sslength ss))

    (setq e (ssname ss i))
    (setq data2 (entget e))
    (setq tipo2 (cdr (assoc 0 data2)))

    (setq p1b nil)

    (cond
      ((= tipo2 "LINE")
        (setq p1b (cdr (assoc 10 data2)))
        (setq p2b (cdr (assoc 11 data2)))
        (setq lenb (distance p1b p2b))
      )

      ((= tipo2 "LWPOLYLINE")
        (setq obj2 (vlax-ename->vla-object e))

        ;; VALIDAR SE É RETA
        (if (isPolylineReta obj2 tolAng)
          (progn
            (setq p1b (vlax-curve-getStartPoint obj2))
            (setq p2b (vlax-curve-getEndPoint obj2))
            (setq lenb (vlax-curve-getDistAtParam obj2
                          (vlax-curve-getEndParam obj2)))
          )
          (setq p1b nil) ;; descarta
        )
      )
    )

    (if p1b
      (progn
        ;; ângulo
        (setq angb (angle p1b p2b))
        (if (< angb 0) (setq angb (+ angb (* 2 pi))))

        ;; centro
        (if (or (< (abs angb) 0.1) (< (abs (- angb pi)) 0.1))
          (setq eixoValb (/ (+ (cadr p1b) (cadr p2b)) 2.0))
          (setq eixoValb (/ (+ (car p1b) (car p2b)) 2.0))
        )

        ;; diferença angular
        (setq angDiff (abs (- ang angb)))

        (if (> angDiff pi)
          (setq angDiff (- (* 2 pi) angDiff))
        )

        (if (> angDiff (/ pi 2))
          (setq angDiff (- pi angDiff))
        )

        ;; filtro final
        (if (and
              (< angDiff tolAng)
              (< (/ (abs (- len lenb)) len) tolLen)
              (< (abs (- eixoVal eixoValb)) tolAxis)
            )
          (ssadd e ssOut)
        )
      )
    )

    (setq i (1+ i))
  )

  ;; =========================
  ;; RESULTADO
  ;; =========================
  (if (> (sslength ssOut) 0)
    (progn
      (sssetfirst nil ssOut)
      (prompt
        (strcat "\nSelecionados "
                (itoa (sslength ssOut))
                " objetos semelhantes.")
      )
    )
    (prompt "\nNenhum objeto semelhante encontrado.")
  )

  (princ)
)