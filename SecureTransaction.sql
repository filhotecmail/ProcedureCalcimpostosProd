EXECUTE BLOCK (

    IN_B001DATETIME TIMESTAMP   = :IN_B001DATETIME,
    IN_B002NATOP VARCHAR(200)   = :IN_B002NATOP,
    IN_B003NROPDV SMALLINT      = :IN_B003NROPDV,
    IN_B004OPERADOR VARCHAR(60) = :IN_B004OPERADOR,
    IN_B005SIT INTEGER          = :IN_B005SIT,
    IN_B006IDMOVCAIXA INTEGER   = :IN_B006IDMOVCAIXA,
    IN_B007IDSESSAO INTEGER     = :IN_B007IDSESSAO )

 RETURNS(

    ID BIGINT,
    B001DATETIME TIMESTAMP,
    B002NATOP VARCHAR(200),
    B003NROPDV SMALLINT,
    B004OPERADOR VARCHAR(60),
    B005SIT INTEGER,
    B006IDMOVCAIXA INTEGER,
    B007IDSESSAO INTEGER,
    B008VOLUME SMALLINT,

    CNPJ VARCHAR(17),
    XNOME VARCHAR(60),
    XFANT VARCHAR(60),
    XLGR VARCHAR(60),
    NRO VARCHAR(60),
    XCPL VARCHAR(60),
    XBAIRRO VARCHAR(60),
    CMUN INTEGER,
    XMUN VARCHAR(60),
    UF VARCHAR(2),
    CEP INTEGER,

    CPAIS SMALLINT,
    XPAIS VARCHAR(60),
    FONE VARCHAR(35),
    XMAIL VARCHAR(200),
    C18IEST VARCHAR(14),
    C17IE VARCHAR(14),
    C19IM VARCHAR(15),
    C20CNAE VARCHAR(7),
    C21CRT INTEGER
    )
 AS
  DECLARE VARIABLE SLINEBREAK CHAR(23);
  DECLARE VARIABLE MOVCAIXAEXISTS SMALLINT;
  DECLARE VARIABLE CAIXAISCLOSE SMALLINT;
  DECLARE VARIABLE SESSIONEXISTS SMALLINT;
  DECLARE VARIABLE SESSIONISACTIVE SMALLINT;
  DECLARE VARIABLE SESSIONHASINCAIXA SMALLINT;
  BEGIN

  SLINEBREAK        = ''||ASCII_CHAR(13) || ASCII_CHAR(10)||'';

  MOVCAIXAEXISTS    =  IIF( ( select count(ID) from CX001 C1
                             WHERE C1.ID = :IN_B006IDMOVCAIXA  )> 0 , 1,0 );

  CAIXAISCLOSE      =  IIF( ( select C2.C007SIT from CX001 C2
                             WHERE C2.ID = :IN_B006IDMOVCAIXA  ) > 0 , 1,0 );

  SESSIONEXISTS     =  IIF( ( select COUNT(C3.ID) from CX002 C3
                             WHERE C3.ID = :IN_B007IDSESSAO  ) > 0 , 1,0 );

  SESSIONISACTIVE   =  IIF( ( select C4.C006STATUS from CX002 C4
                             WHERE C4.ID = :IN_B007IDSESSAO  ) = 0 , 1,0 );

  SESSIONHASINCAIXA =  IIF( ( select IIF( C5.C001IDCAIXA = :IN_B006IDMOVCAIXA,1,0 )
                               from CX002 C5
                              WHERE C5.ID = :IN_B007IDSESSAO  ) = 1 , 1,0 );

 IF ( :IN_B001DATETIME IS NULL ) THEN
    EXCEPTION EEBADPARAM 'O parametro IN_B001DATETIME nao pode ser null '
    ||'informe uma DATABASE do tipo TimeStamp '
    ||:SLINEBREAK||'Esse erro e: O para metro IN_B001DATETIME nao foi '
    ||'informado, o parametro corresponde a '
    ||:SLINEBREAK||'Data e hora da transacao no formato TIMESTAMP ';

 IF ( :IN_B002NATOP IS NULL OR ( CHAR_LENGTH(:IN_B002NATOP) <= 0 )  ) THEN
     EXCEPTION EEBADPARAM 'O parametro in_B002NATOP nao pode ser null,'
    ||SLINEBREAK|| ' ex: de preenchimento "VENDA DE MERCADORIA ADIQUIRIRA '
    ||'OU RECEBIDA DE TERCEIROS" ';

 IF ( :IN_B003NROPDV IS NULL OR ( CHAR_LENGTH(:IN_B003NROPDV) <= 0 )  ) THEN
     EXCEPTION EEBADPARAM 'O parametro in_B003NROPDV nao pode ser null';

 IF ( :IN_B004OPERADOR IS NULL OR ( CHAR_LENGTH(:IN_B004OPERADOR) <= 0 )  ) THEN
     EXCEPTION EEBADPARAM 'O parametro in_B004OPERADOR nao pode ser null ou vazio,'
    ||SLINEBREAK|| ' ex: de preenchimento "NOME DO OPERADOR DE CAIXA" ';

 IF ( :IN_B005SIT IS NULL OR ( CHAR_LENGTH(:IN_B005SIT) <= 0 )  ) THEN
     EXCEPTION EEBADPARAM 'O parametro in_B005SIT nao pode ser null,'
    ||SLINEBREAK||' Informe a situacao da venda"  '
    ||slinebreak||'0 VENDA ABERTA'
    ||slinebreak||'1 VENDA FECHADA'
    ||slinebreak||'2 VENDA CANCELADA'
    ||slinebreak||'3 VENDA ESTORNADA';

 IF ( :IN_B006IDMOVCAIXA IS NULL OR ( CHAR_LENGTH(:IN_B006IDMOVCAIXA) <= 0 ) ) THEN
    EXCEPTION EEBADPARAM 'O parametro in_B004OPERADOR nao pode ser null ou vazio,'
  ||SLINEBREAK|| ' ex: de preenchimento "NOME DO OPERADOR DE CAIXA" ';

  IF ( MOVCAIXAEXISTS <= 0 ) THEN
    EXCEPTION EEBADPARAM 'Nao existe um movimento de caixa na tabela CX001 com '
    ||'o ID do movimento de caixa informado'
    ||SLINEBREAK|| ' Esse erro é : O Parametro in_B006IDMOVCAIXA deve ser um '
    ||'ID válido na tabela ';

  IF ( CAIXAISCLOSE = 1 ) THEN
    EXCEPTION EEBADPARAM 'Nao e possivel abrir uma venda na tabela IDE se '
    ||'o Movimento de caixa estiver fechado!'
    ||SLINEBREAK||' Esse erro é : O Parametro in_B006IDMOVCAIXA deve ser um ID de  '
    ||SLINEBREAK||'Movimento de caixa da tabela CX001 com a situacao 0 "ABERTO" ';

  IF ( :IN_B007IDSESSAO IS NULL OR ( CHAR_LENGTH(:IN_B007IDSESSAO) <= 0 ) ) THEN
    EXCEPTION EEBADPARAM 'O parametro IN_B007IDSESSAO nao pode ser null ou vazio,'
    ||SLINEBREAK|| ' o ID de uma sessão logada no caixa é necessario '
    ||SLINEBREAK|| ' "Nao e possivel abrir uma venda sem um operador de '
    ||'caixa logado na sessao"  ';

  IF ( SESSIONEXISTS < 1 ) THEN
     EXCEPTION EEBADPARAM 'Nao existe uma sessao de caixa aberta com o '
     ||'ID de sessao informado no parametro IN_B007IDSESSAO de valor ,'||:IN_B007IDSESSAO
    ||SLINEBREAK|| ' o ID de uma sessão logada no caixa é necessario '
    ||SLINEBREAK|| ' "Nao e possivel abrir uma venda sem um operador de '
    ||'caixa logado na sessao"  ';

  IF ( SESSIONISACTIVE < 1 ) THEN
    EXCEPTION EEBADPARAM 'A sessao de caixa esta FECHADA com status 0 , informado'
    ||' no parametro IN_B007IDSESSAO de valor ,'||:IN_B007IDSESSAO
    ||SLINEBREAK|| ' E necessaria uma sessao ativa para inserir novas vendas'
    ||' na tabela IDE '
    ||SLINEBREAK|| ' "Nao e possivel abrir uma venda sem uma sessao ativa"  ';

  IF ( SESSIONHASINCAIXA < 1 ) THEN
     EXCEPTION EEBADPARAM 'A sessao nao pertence ao movimento de caixa informado '
    ||'no parametro IN_B006IDMOVCAIXA de valor ,'||:IN_B006IDMOVCAIXA
    ||SLINEBREAK|| ' E necessaria uma sessao ativa para inserir novas vendas '
    ||'na tabela IDE '
    ||SLINEBREAK|| ' "Divergencia de informacoes, o ID de sessao nao pertence '
    ||'ao ID de caixa"  ';

  IN AUTONOMOUS TRANSACTION DO
   INSERT INTO IDE (B001DATETIME, B002NATOP, B003NROPDV, B004OPERADOR,
                    B005SIT, B006IDMOVCAIXA, B007IDSESSAO)
   VALUES (:in_B001DATETIME, :in_B002NATOP, :in_B003NROPDV, :in_B004OPERADOR,
           :in_B005SIT, :in_B006IDMOVCAIXA, :in_B007IDSESSAO )

   RETURNING ID,B001DATETIME,B002NATOP, B003NROPDV,
             B004OPERADOR, B005SIT, B006IDMOVCAIXA,
             B007IDSESSAO

   INTO  :ID,
         :B001DATETIME,
         :B002NATOP,
         :B003NROPDV ,
         :B004OPERADOR,
         :B005SIT ,
         :B006IDMOVCAIXA ,
         :B007IDSESSAO;

 SELECT CNPJ, XNOME, XFANT, XLGR, NRO, XCPL, XBAIRRO, CMUN, XMUN, UF, CEP,
           CPAIS, XPAIS, FONE, XMAIL, C18IEST,C17IE, C19IM, C20CNAE, C21CRT
 FROM EMIT E WHERE E.IDPK = :ID

 INTO
    :CNPJ,
    :XNOME ,
    :XFANT ,
    :XLGR ,
    :NRO ,
    :XCPL ,
    :XBAIRRO,
    :CMUN ,
    :XMUN ,
    :UF ,
    :CEP ,
    :CPAIS ,
    :XPAIS ,
    :FONE ,
    :XMAIL ,
    :C18IEST ,
    :C17IE ,
    :C19IM ,
    :C20CNAE ,
    :C21CRT;

  SUSPEND;

 END
