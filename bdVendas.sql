CREATE DATABASE bdVendas
GO
USE bdVendas
CREATE TABLE tbProduto(
	codigo			INT				NOT NULL
	, nome			VARCHAR(40)		NOT NULL
	, descricao		VARCHAR(100)	NOT NULL
	, valorUnitario DECIMAL(7,2)	NOT NULL	DEFAULT 0
	PRIMARY KEY (codigo)
);
GO
CREATE TABLE tbEstoque(
	codProduto		INT				NOT NULL
	, qtdEstoque	INT				NOT NULL
	, estoqueMin	INT				NOT NULL
	PRIMARY KEY(codProduto)
);
GO
CREATE TABLE tbVenda(
	notaFiscal		INT				NOT NULL
	, codProduto	INT				NOT NULL
	, qtd			INT				NOT NULL
	PRIMARY KEY (notaFiscal)
);
GO
--===========================================================================
CREATE TRIGGER tg_venda_insert_disp_estoque
ON tbVenda
AFTER INSERT
AS
BEGIN
	DECLARE @qtdEstoque INT
			,@codP INT
			,@qtdVenda INT
			,@qtdMinima INT
			,@nomeProduto VARCHAR(40)

	SELECT @codP = codProduto
			,@qtdVenda = qtd
	FROM inserted

	SELECT @qtdEstoque = qtdEstoque 
		,@qtdMinima = estoqueMin
	FROM tbEstoque
	WHERE codProduto = @codP

	IF (NOT (@qtdVenda <= @qtdEstoque))
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR('Não há estoque suficiente para realizar a venda',16,1)
	END
	ELSE
	BEGIN
		UPDATE tbEstoque
		SET qtdEstoque = qtdEstoque - @qtdVenda
		WHERE codProduto = @codP

		SELECT @qtdEstoque = e.qtdEstoque 
			,@qtdMinima = e.estoqueMin
			,@nomeProduto = p.nome
		FROM tbEstoque as e, tbProduto as p
		WHERE e.codProduto = p.codigo AND p.codigo = @codP

		IF(@qtdEstoque < @qtdMinima)
		BEGIN
			PRINT 'O estoque do produto ' + @nomeProduto +' está abaixo do mínimo'
		END
	END
END
GO
--===========================================================================
CREATE FUNCTION fn_notaFiscal(@nota INT)
RETURNS @tab TABLE(notaFiscal INT,codigoProduto INT,nomeProduto VARCHAR(40),descProduto VARCHAR(100),valorUnitario DECIMAL(7,2),quantidade INT,valorTotal DECIMAL(7,2))
AS
BEGIN
	INSERT INTO @tab 
	SELECT 
		vd.notaFiscal
		, pd.codigo AS codigoProduto
		, pd.nome AS nomeProduto
		, pd.descricao AS descProduto
		, pd.valorUnitario
		, vd.qtd AS quantidade
		, (pd.valorUnitario * vd.qtd) AS valorTotal
	FROM tbVenda AS vd, tbProduto AS pd
	WHERE vd.codProduto = pd.codigo AND vd.notaFiscal = @nota
	RETURN		
END
--===========================================================================