SET TERM ^ ;

CREATE OR ALTER PROCEDURE SALESPROD (
    I001AIDPK BIGINT,
    I02CPROD VARCHAR(60),
    I03CEAN VARCHAR(14),
    I04XPROD VARCHAR(120),
    I05NCM VARCHAR(8),
    I09UCOM VARCHAR(6),
    I10QCOM NUMERIC(15,4),
    I10AVUNCOM NUMERIC(15,2),
    I12CEANTRIB VARCHAR(14),
    I13UTRIB VARCHAR(6),
    I14QTRIB NUMERIC(15,4),
    I14AVUNTRIB NUMERIC(15,2),
    I15VFRETE NUMERIC(15,2),
    I16VSEG NUMERIC(15,2),
    I17VDESC NUMERIC(15,2),
    I17AVOUTRO NUMERIC(15,2),
    I17BINDTOT INTEGER,
    I05CCEST VARCHAR(7),
    IVLCUSTOPROD NUMERIC(15,2),
    PICMSORIG SMALLINT,
    PCSTCSOSN VARCHAR(3),
    PPICMS NUMERIC(15,4),
    PPIS_CST CHAR(3),
    PPIS_ALIQ NUMERIC(15,4),
    PCOFINS_CST CHAR(3),
    PCOFINS_ALIQ NUMERIC(15,4),
    PVOLUMECONFIG SMALLINT)
RETURNS (
    LID BIGINT,
    LI001AIDPK BIGINT,
    LH02NITEM INTEGER,
    LI02CPROD VARCHAR(60),
    LI03CEAN VARCHAR(14) CHARACTER SET ISO8859_1,
    LI04XPROD VARCHAR(120),
    LI05NCM VARCHAR(8),
    LI08CFOP VARCHAR(4),
    LI09UCOM VARCHAR(6),
    LI10QCOM NUMERIC(15,4),
    LI10AVUNCOM NUMERIC(15,2),
    LI11VPROD NUMERIC(15,2),
    LI12CEANTRIB VARCHAR(14),
    LI13UTRIB VARCHAR(6),
    LI14QTRIB NUMERIC(15,4),
    LI14AVUNTRIB NUMERIC(15,2),
    LI15VFRETE NUMERIC(15,2),
    LI16VSEG NUMERIC(15,2),
    LI17VDESC NUMERIC(15,2),
    LI17AVOUTRO NUMERIC(15,2),
    LI17BINDTOT INTEGER,
    LI05CCEST VARCHAR(7),
    LICMS_ICMSORIG SMALLINT,
    LICMS_CSTCSOSN VARCHAR(3),
    LICMS_PICMS NUMERIC(15,4),
    LICMS_PIS_CST CHAR(3),
    LICMS_PIS_ALIQ NUMERIC(15,4),
    LICMS_COFINS_CST CHAR(3),
    LICMS_COFINS_ALIQ NUMERIC(15,4),
    LICMS_CFOP VARCHAR(4),
    LIBPT_ALIQMUN NUMERIC(15,4),
    LIBPT_ALIQEST NUMERIC(15,4),
    LIBPT_ALIQFED NUMERIC(15,4),
    LIBPT_ALIQIMP NUMERIC(15,4),
    LVOLUME SMALLINT,
    LCARTAZIBPT VARCHAR(255),
    LNATOP VARCHAR(255),
    LICMS_ALIQ NUMERIC(15,4),
    LPFICMS_CSTCSOSN VARCHAR(5),
    LPFICMS_PERCREDBC NUMERIC(15,4))
AS
DECLARE VARIABLE LINCPOSITION SMALLINT = 0;
DECLARE VARIABLE LRETURNPOSITION SMALLINT = 0;
DECLARE VARIABLE LCPRODEE CHAR(1) = 0;
DECLARE VARIABLE LXDESCEE CHAR(1) = 0;
DECLARE VARIABLE LANSIXPROD VARCHAR(120) CHARACTER SET ISO8859_1;
DECLARE VARIABLE L_VALUEUNIDPROD NUMERIC(15,2) = 1;
DECLARE VARIABLE L_QTDPROD NUMERIC(15,4) = 1;
DECLARE VARIABLE L_UNIDPROD VARCHAR(6) = 'UNID';
DECLARE VARIABLE L_I11VPROD NUMERIC(15,2);
DECLARE VARIABLE L_PRODUTOEXISTE SMALLINT = 0;
DECLARE VARIABLE VIBPT_ALIQMUN NUMERIC(15,2); /* RESULTADO DO CALCULO VALOR DO IMPOSTO MUNICIPAL */
DECLARE VARIABLE VIBPT_ALIQEST NUMERIC(15,2); /* RESULTADO DO CALCULO VALOR DO IMPOSTO ESTADUAL */
DECLARE VARIABLE VIBPT_ALIQFED NUMERIC(15,2); /* RESULTADO DO CALCULO VALOR DO IMPOSTO FEDERAL */
DECLARE VARIABLE VIBPT_ALIQIMP NUMERIC(15,2); /* RESULTADO DO CALCULO VALOR DO IMPOSTO IMPORTADO */
DECLARE VARIABLE I08CFOP VARCHAR(5);

DECLARE VARIABLE PFNATOP TYPE OF COLUMN PERFILTRIBUTARIO.NATOP;
DECLARE VARIABLE PFCFOP TYPE OF COLUMN PERFILTRIBUTARIO.CFOP;
DECLARE VARIABLE PFICMS_ALIQ TYPE OF COLUMN PERFILTRIBUTARIO.ICMS_ALIQ;
DECLARE VARIABLE PFICMS_CSTCSOSN TYPE OF COLUMN PERFILTRIBUTARIO.ICMS_CSTCSOSN;
DECLARE VARIABLE PFICMS_PERCREDBC TYPE OF COLUMN PERFILTRIBUTARIO.ICMS_PERCREDBC;
DECLARE VARIABLE PFPIS_CST TYPE OF COLUMN PERFILTRIBUTARIO.PIS_CST;
DECLARE VARIABLE PFPIS_ALIQ TYPE OF COLUMN PERFILTRIBUTARIO.PIS_ALIQ;
DECLARE VARIABLE PFCOFINS_CST TYPE OF COLUMN PERFILTRIBUTARIO.COFINS_CST;
DECLARE VARIABLE PFCOFINS_ALIQ TYPE OF COLUMN PERFILTRIBUTARIO.COFINS_ALIQ;
DECLARE VARIABLE PFMODBC TYPE OF COLUMN PERFILTRIBUTARIO.MODBC;
DECLARE VARIABLE PFORIGEM TYPE OF COLUMN PERFILTRIBUTARIO.ORIGEM;
DECLARE VARIABLE PFDESCRICAO TYPE OF COLUMN PERFILTRIBUTARIO.DESCRICAO;
DECLARE VARIABLE PFNCM TYPE OF COLUMN PERFILTRIBUTARIO.NCM;

BEGIN

/*
     RECUPERA O VOLUME ATUAL DA VENDA
     DEVA -SE RECUPERAR O VOLUME ATUAL DA VENDA PARA CALCULAR O VOLUME
     MAIS DO MESMO PRODUTO ?? EQUIVALENTE A 1 VOLUME
     PRODUTOS DIFERENTES ?? EQUIVALENTE A + 1 VOLUME

*/

 LVOLUME         =   COALESCE(( SELECT E.B008VOLUME FROM IDE E WHERE E.ID = :I001AIDPK ),0);
 L_PRODUTOEXISTE = ( SELECT COUNT( PP.ID ) FROM PROD PP WHERE PP.I02CPROD = :I02CPROD  );

  SELECT COALESCE(B.ALIQMUN,0) ,
        COALESCE( B.ALIQEST,18.00 ),
        COALESCE( B.ALIQFED,15.10 ) ,
        COALESCE( B.ALIQIMP,15.10 ) FROM  IBPTAX B WHERE B.NCM = :I05NCM
  INTO :LIBPT_ALIQMUN,
       :LIBPT_ALIQEST,
       :LIBPT_ALIQFED,
       :LIBPT_ALIQIMP;

/*
  *****************************************************************************

   SE HOUVER UM BLOQUEIO DE VOLUME A QUANTIDADE PARA INFORMAR O
   BLOQUEUIO SER?? MAIOR QUE ZERO

  *****************************************************************************

   SE EXIRTIR O MESMO PRODUTO JA REGISTRADO NA TABELA DE VENDAS DA VENDA DE IDPK
   X NAO INCREMENTA O VOLUME , SE FOR UM PRODUTO NOVO, OU SEJA NAO
   EXISTE NA TABELA SE O BLOQUEIO DE TRAVA DE CAIXA RAPIDO ESTIVER CONFIGURADO
   E SE O VOLUME ATUAL FOR MAIOR OU IGUAL AO VOLUME MAX ACEITO

    -> PARA A TRANSA????O
       CASO N??O INCREMENTA +1 NO VOLUME DE VENDAS JA REGISTRADO

  *****************************************************************************
*/

   IF ( L_PRODUTOEXISTE <= 0 ) THEN
   BEGIN
      IF (( PVOLUMECONFIG > 0 )
        AND ( ( LVOLUME  >= PVOLUMECONFIG ) ) ) THEN EXCEPTION EEVOLUMEEXCEDIDO ;

         LVOLUME = LVOLUME + 1 ;
    END

/*
 -----------------------------------------------------------------------------
 REMOVE CARACTERES , ASCENTOS DA STRING
 -----------------------------------------------------------------------------
*/
  LANSIXPROD =  ( SELECT RESULT FROM ISONOASC(:I04XPROD) );

  LCPRODEE = IIF((( :I02CPROD IS NULL )
             OR ( CHARACTER_LENGTH( TRIM(:I02CPROD) ) <= 0  ) ),1,0 );

  LXDESCEE = IIF((( LANSIXPROD IS NULL )
             OR ( CHARACTER_LENGTH( TRIM(LANSIXPROD) ) <= 0  ) ),1,0 );

 IF ( LCPRODEE > 0 ) THEN  EXCEPTION EECODOPRODISNULLOREMPT;
 IF ( LXDESCEE > 0 ) THEN  EXCEPTION EEXPRODISNULLOREMPT;

 IF ( CHARACTER_LENGTH(:I05NCM) < 8 ) THEN I05NCM = '99999999';

 L_UNIDPROD = IIF((( :I09UCOM IS NULL )
  OR ( CHARACTER_LENGTH( TRIM(:I09UCOM) ) <= 0  ) ),'UNID',:I09UCOM );


 /*
  **************************************************************************
   RECUPERA OS DADOS DA TRIBUTA????O ICMS DO PODUTO
  **************************************************************************
 */

  SELECT NATOP,
         CFOP, ICMS_ALIQ, ICMS_CSTCSOSN, ICMS_PERCREDBC, PIS_CST, PIS_ALIQ,
         COFINS_CST, COFINS_ALIQ, MODBC, ORIGEM, DESCRICAO, PF.NCM
   FROM PERFILTRIBUTARIO PF
  WHERE PF.NCM = :I05NCM

  INTO
    :PFNATOP,
    :PFCFOP,
    :PFICMS_ALIQ,
    :PFICMS_CSTCSOSN,
    :PFICMS_PERCREDBC,
    :PFPIS_CST,
    :PFPIS_ALIQ,
    :PFCOFINS_CST,
    :PFCOFINS_ALIQ,
    :PFMODBC,
    :PFORIGEM,
    :PFDESCRICAO,
    :PFNCM; 

  I08CFOP    = :PFCFOP;
  LNATOP     = :PFNATOP;
  LICMS_ALIQ        = :PFICMS_ALIQ;
  LPFICMS_CSTCSOSN  = :PFICMS_CSTCSOSN;
  LPFICMS_PERCREDBC = :PFICMS_PERCREDBC;

/****************************************************************************

      CALCULA TODO O NECESSARIO PARA A VENDA DO PRODUTO
      CALCULA O VALOR TOTAL DO PRODUTO COM BASE EM
      VALOR UNITARIO DO PRODUTO X QUANTIDADE VENDIDA
      (  - DESCONTOS + ACRESCIMOS )

*/

    L_VALUEUNIDPROD = I10AVUNCOM;
    L_QTDPROD       = I10QCOM;
    L_I11VPROD      =  ( L_VALUEUNIDPROD * L_QTDPROD );

/****************************************************************************/
/* CALCULA CARTAZ IBPT*/

  VIBPT_ALIQMUN  = (( L_I11VPROD * LIBPT_ALIQMUN  ) / 100);
  VIBPT_ALIQEST  = (( L_I11VPROD * LIBPT_ALIQEST  ) / 100);
  VIBPT_ALIQFED  = (( L_I11VPROD * LIBPT_ALIQFED  ) / 100);
  VIBPT_ALIQIMP  = (( L_I11VPROD * LIBPT_ALIQIMP  ) / 100);

  LCARTAZIBPT = 'VALOR APROX TRIBUTOS MUN. : R$ ' || VIBPT_ALIQMUN ||'( '  ||CAST(LIBPT_ALIQMUN AS NUMERIC(15,2) ) ||'% ),'
              ||' EST. : R$ '    || VIBPT_ALIQEST ||'( '  ||  CAST(LIBPT_ALIQEST AS NUMERIC(15,2) ) ||'% ),'
              ||' FED. : R$ '    || VIBPT_ALIQFED ||'( '  ||  CAST(LIBPT_ALIQFED AS NUMERIC(15,2) ) ||'% ),'
              ||' IMP. : R$ '    || VIBPT_ALIQIMP ||'( '  ||  CAST(LIBPT_ALIQIMP AS NUMERIC(15,2) ) ||'% ),'
              ||' FONTE: IBPT';


/*****************************************************************************/


 /*
   CALCULA A POSICAO DO ITEM, OU SEJA O ULTIMO ITEM INSERIDO + 1
*/
 LINCPOSITION = ( SELECT
                       CAST(COUNT( P2.ID ) + 1 AS SMALLINT) AS LPOSITION
                       FROM PROD P2  WHERE P2.I001AIDPK = :I001AIDPK);
 /*
    RETORNA A POSI????O DO ITEM APOS INCREMENTADO
  */
 LRETURNPOSITION =  ( SELECT
                      CAST(COUNT( ID ) AS SMALLINT) AS LPOSITION
                      FROM PROD P WHERE P.I001AIDPK = :I001AIDPK);



 INSERT INTO PROD ( I001AIDPK,H02NITEM, I02CPROD, I03CEAN, I04XPROD, I05NCM,
                    I08CFOP,I09UCOM, I10QCOM, I10AVUNCOM, I11VPROD, I12CEANTRIB,
                    I13UTRIB, I14QTRIB, I14AVUNTRIB, I15VFRETE, I16VSEG,
                    I17VDESC, I17AVOUTRO, I17BINDTOT, I05CCEST,IVLCUSTOPROD )

  VALUES ( :I001AIDPK,:LINCPOSITION, :I02CPROD, :I03CEAN, :LANSIXPROD,
           :I05NCM,:I08CFOP, :L_UNIDPROD, :I10QCOM, :I10AVUNCOM,
           :L_I11VPROD, :I12CEANTRIB, :I13UTRIB, :I14QTRIB, :I14AVUNTRIB,
           :I15VFRETE, :I16VSEG, :I17VDESC, :I17AVOUTRO, :I17BINDTOT, :I05CCEST,
           :IVLCUSTOPROD )

  RETURNING ID,
            I001AIDPK,:LRETURNPOSITION, I02CPROD, I03CEAN, I04XPROD,
            I05NCM, I08CFOP, I09UCOM, I10QCOM, I10AVUNCOM, I11VPROD,
            I12CEANTRIB, I13UTRIB, I14QTRIB, I14AVUNTRIB, I15VFRETE,
            I16VSEG, I17VDESC, I17AVOUTRO, I17BINDTOT, I05CCEST
  INTO
    :LID, :LI001AIDPK, :LH02NITEM, :LI02CPROD, :LI03CEAN,:LI04XPROD,  :LI05NCM,
    :LI08CFOP, :LI09UCOM, :LI10QCOM, :LI10AVUNCOM,:LI11VPROD,  :LI12CEANTRIB,
    :LI13UTRIB, :LI14QTRIB, :LI14AVUNTRIB, :LI15VFRETE, :LI16VSEG,  :LI17VDESC,
    :LI17AVOUTRO, :LI17BINDTOT,:LI05CCEST;

/*
  ----------------------------------------------------------------------------
   INSERE OS IMPOSTOS DE SAIDA | DADOS ATEMPORAIS DA TABELA FILHA
  ----------------------------------------------------------------------------
 */
 INSERT INTO PROD_ICMS (IDPK, ICMSORIG, CSTCSOSN, PICMS, PIS_CST, PIS_ALIQ,
                        COFINS_CST, COFINS_ALIQ, CFOP,
                        IBPT_ALIQMUN,
                        IBPT_ALIQEST,
                        IBPT_ALIQFED,
                        IBPT_ALIQIMP)

 VALUES (:LID, :PICMSORIG, :PCSTCSOSN, :PPICMS, :PPIS_CST,
         :PPIS_ALIQ, :PCOFINS_CST, :PCOFINS_ALIQ, :PFCFOP,
         COALESCE(:LIBPT_ALIQMUN,0),
         COALESCE(:LIBPT_ALIQEST,18.00),
         COALESCE(:LIBPT_ALIQFED,15.10),
         COALESCE(:LIBPT_ALIQIMP, 15.10 ))

 RETURNING ICMSORIG, CSTCSOSN, PICMS, PIS_CST, PIS_ALIQ, COFINS_CST, COFINS_ALIQ, CFOP,
           IBPT_ALIQMUN, IBPT_ALIQEST,  IBPT_ALIQFED, IBPT_ALIQIMP

 INTO  :LICMS_ICMSORIG,:LICMS_CSTCSOSN,:LICMS_PICMS, :LICMS_PIS_CST,
       :LICMS_PIS_ALIQ,:LICMS_COFINS_CST,:LICMS_COFINS_ALIQ, :LICMS_CFOP,
       :LIBPT_ALIQMUN,:LIBPT_ALIQEST,:LIBPT_ALIQFED,:LIBPT_ALIQIMP;

 /*  END INSERE IMPOSTOS SAIDA  */

 /*
   ----------------------------------------------------------------------------
   ATUALIZA O VOLUME DA COMPRA TABELA DE VENDAS IDE
   ----------------------------------------------------------------------------
 */
  UPDATE IDE SET B008VOLUME = :LVOLUME
  WHERE (ID = :I001AIDPK);

  SUSPEND;

END^

SET TERM ; ^

/* FOLLOWING GRANT STATETEMENTS ARE GENERATED AUTOMATICALLY */

GRANT SELECT,UPDATE ON IDE TO PROCEDURE SALESPROD;
GRANT SELECT,INSERT ON PROD TO PROCEDURE SALESPROD;
GRANT SELECT ON IBPTAX TO PROCEDURE SALESPROD;
GRANT EXECUTE ON PROCEDURE ISONOASC TO PROCEDURE SALESPROD;
GRANT SELECT ON PERFILTRIBUTARIO TO PROCEDURE SALESPROD;
GRANT INSERT ON PROD_ICMS TO PROCEDURE SALESPROD;

/* EXISTING PRIVILEGES ON THIS PROCEDURE */

GRANT EXECUTE ON PROCEDURE SALESPROD TO SYSDBA;
