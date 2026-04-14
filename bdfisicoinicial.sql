/* Modelo_Lógico_1: */

CREATE TABLE Usuario (
    id_usuario INTEGER,
    nome VARCHAR,
    email VARCHAR,
    telefone VARCHAR,
    senha VARCHAR,
    data_cadastro DATE,
    status VARCHAR,
    id_responsavel INTEGER,
    fk_Aluno_id_aluno INTEGER,
    fk_Aluno_id_responsavel INTEGER,
    fk_Notificacao_id_notificacao INTEGER,
    PRIMARY KEY (id_usuario, id_responsavel)
);

CREATE TABLE Aluno (
    id_aluno INTEGER,
    id_responsavel INTEGER,
    fk_Aluno_id_aluno INTEGER,
    fk_Aluno_id_responsavel INTEGER,
    fk_Presenca_id_presenca INTEGER,
    fk_Notificacao_id_notificacao INTEGER,
    PRIMARY KEY (id_aluno, id_responsavel)
);

CREATE TABLE Motorista (
    id_motorista INTEGER,
    CNH VARCHAR,
    id_responsavel INTEGER,
    fk_Aluno_id_aluno INTEGER,
    fk_Aluno_id_responsavel INTEGER,
    fk_Rota_id_rota INTEGER,
    fk_Notificacao_id_notificacao INTEGER,
    PRIMARY KEY (id_motorista, id_responsavel)
);

CREATE TABLE Administrador (
    id_responsavel INTEGER PRIMARY KEY,
    fk_Aluno_id_aluno INTEGER,
    fk_Aluno_id_responsavel INTEGER,
    fk_Notificacao_id_notificacao INTEGER
);

CREATE TABLE QR_CODE (
    id_qrcode INTEGER PRIMARY KEY,
    codigo VARCHAR,
    FK_Aluno_id_aluno INTEGER,
    FK_Aluno_id_responsavel INTEGER
);

CREATE TABLE Presenca (
    id_presenca INTEGER PRIMARY KEY,
    horario_entrada DATE,
    horario_saida DATE,
    status VARCHAR,
    latitude DECIMAL,
    longitude DECIMAL
);

CREATE TABLE Rota (
    id_rota INTEGER PRIMARY KEY,
    data DATE,
    status VARCHAR,
    fk_Presenca_id_presenca INTEGER,
    fk_Localizacao_id_localizacao INTEGER
);

CREATE TABLE Localizacao (
    id_localizacao INTEGER PRIMARY KEY,
    latitude DECIMAL,
    longitude DECIMAL,
    timestamp DATE
);

CREATE TABLE Notificacao (
    id_notificacao INTEGER PRIMARY KEY,
    mensagem VARCHAR,
    data_envio DATE
);

CREATE TABLE Ausencia (
    data DATE,
    motivo VARCHAR
);
 
ALTER TABLE Usuario ADD CONSTRAINT FK_Usuario_2
    FOREIGN KEY (fk_Aluno_id_aluno, fk_Aluno_id_responsavel)
    REFERENCES Aluno (id_aluno, id_responsavel)
    ON DELETE RESTRICT;
 
ALTER TABLE Usuario ADD CONSTRAINT FK_Usuario_3
    FOREIGN KEY (fk_Notificacao_id_notificacao)
    REFERENCES Notificacao (id_notificacao)
    ON DELETE CASCADE;
 
ALTER TABLE Aluno ADD CONSTRAINT FK_Aluno_1
    FOREIGN KEY (fk_Aluno_id_aluno, fk_Aluno_id_responsavel)
    REFERENCES Aluno (id_aluno, id_responsavel);
 
ALTER TABLE Aluno ADD CONSTRAINT FK_Aluno_3
    FOREIGN KEY (fk_Presenca_id_presenca)
    REFERENCES Presenca (id_presenca)
    ON DELETE CASCADE;
 
ALTER TABLE Aluno ADD CONSTRAINT FK_Aluno_4
    FOREIGN KEY (fk_Notificacao_id_notificacao)
    REFERENCES Notificacao (id_notificacao)
    ON DELETE CASCADE;
 
ALTER TABLE Motorista ADD CONSTRAINT FK_Motorista_2
    FOREIGN KEY (fk_Aluno_id_aluno, fk_Aluno_id_responsavel)
    REFERENCES Aluno (id_aluno, id_responsavel)
    ON DELETE RESTRICT;
 
ALTER TABLE Motorista ADD CONSTRAINT FK_Motorista_3
    FOREIGN KEY (fk_Rota_id_rota)
    REFERENCES Rota (id_rota)
    ON DELETE CASCADE;
 
ALTER TABLE Motorista ADD CONSTRAINT FK_Motorista_4
    FOREIGN KEY (fk_Notificacao_id_notificacao)
    REFERENCES Notificacao (id_notificacao)
    ON DELETE CASCADE;
 
ALTER TABLE Administrador ADD CONSTRAINT FK_Administrador_2
    FOREIGN KEY (fk_Aluno_id_aluno, fk_Aluno_id_responsavel)
    REFERENCES Aluno (id_aluno, id_responsavel)
    ON DELETE RESTRICT;
 
ALTER TABLE Administrador ADD CONSTRAINT FK_Administrador_3
    FOREIGN KEY (fk_Notificacao_id_notificacao)
    REFERENCES Notificacao (id_notificacao)
    ON DELETE CASCADE;
 
ALTER TABLE QR_CODE ADD CONSTRAINT FK_QR_CODE_2
    FOREIGN KEY (FK_Aluno_id_aluno, FK_Aluno_id_responsavel)
    REFERENCES Aluno (id_aluno, id_responsavel)
    ON DELETE RESTRICT;
 
ALTER TABLE Rota ADD CONSTRAINT FK_Rota_2
    FOREIGN KEY (fk_Presenca_id_presenca)
    REFERENCES Presenca (id_presenca)
    ON DELETE RESTRICT;
 
ALTER TABLE Rota ADD CONSTRAINT FK_Rota_3
    FOREIGN KEY (fk_Localizacao_id_localizacao)
    REFERENCES Localizacao (id_localizacao)
    ON DELETE RESTRICT;
