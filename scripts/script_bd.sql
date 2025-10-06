SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
  BEGIN TRAN;
  IF OBJECT_ID('dbo.Funcionario','U') IS NOT NULL DROP TABLE dbo.Funcionario;
  IF OBJECT_ID('dbo.Empresa','U') IS NOT NULL DROP TABLE dbo.Empresa;
  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  THROW;
END CATCH;
GO

BEGIN TRAN;
CREATE TABLE dbo.Empresa (
  id BIGINT IDENTITY(1,1) PRIMARY KEY,
  nome NVARCHAR(255) NOT NULL
);

CREATE TABLE dbo.Funcionario (
  id BIGINT IDENTITY(1,1) PRIMARY KEY,
  nome NVARCHAR(255) NOT NULL,
  cargo NVARCHAR(255) NOT NULL,
  empresa_id BIGINT NOT NULL,
  CONSTRAINT FK_Funcionario_Empresa FOREIGN KEY (empresa_id) REFERENCES dbo.Empresa(id)
);
COMMIT TRAN;
GO

-- Seed de exemplo
INSERT INTO dbo.Empresa (nome) VALUES (N'DimDim Tecnologia');
INSERT INTO dbo.Funcionario (nome, cargo, empresa_id) VALUES (N'João Silva', N'Analista', 1);
INSERT INTO dbo.Funcionario (nome, cargo, empresa_id) VALUES (N'Maria Souza', N'Desenvolvedora', 1);
GO
