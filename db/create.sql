CREATE TABLE tbl_keyType (
  ID BIGSERIAL   NOT NULL ,
  name VARCHAR(45)   NOT NULL   ,
PRIMARY KEY(ID));




CREATE TABLE tbl_Right (
  ID BIGSERIAL   NOT NULL ,
  name VARCHAR(45)   NOT NULL   ,
PRIMARY KEY(ID));




CREATE TABLE tbl_Role (
  ID BIGSERIAL   NOT NULL ,
  name VARCHAR(45)   NOT NULL   ,
PRIMARY KEY(ID));




CREATE TABLE tbl_User (
  ID BIGSERIAL   NOT NULL ,
  tbl_Role_ID BIGSERIAL   NOT NULL ,
  firstName VARCHAR(45)   NOT NULL ,
  lastName VARCHAR(45)   NOT NULL ,
  email VARCHAR(255)   NOT NULL ,
  active BOOL   NOT NULL ,
  userName VARCHAR(255) UNIQUE  NOT NULL,
  pass BYTEA   NOT NULL ,
  salt BYTEA   NOT NULL   ,
PRIMARY KEY(ID)  ,
  FOREIGN KEY(tbl_Role_ID)
    REFERENCES tbl_Role(ID));


CREATE INDEX tbl_User_FKIndex1 ON tbl_User (tbl_Role_ID);




CREATE INDEX IFK_Rel_01 ON tbl_User (tbl_Role_ID);


CREATE TABLE tbl_DocKey (
  ID BIGSERIAL   NOT NULL ,
  tbl_keyType_ID BIGSERIAL   NOT NULL ,
  keyData BYTEA   NOT NULL ,
  keyIv BYTEA   NOT NULL   ,
PRIMARY KEY(ID)  ,
  FOREIGN KEY(tbl_keyType_ID)
    REFERENCES tbl_keyType(ID));


CREATE INDEX tbl_DocKey_FKIndex2 ON tbl_DocKey (tbl_keyType_ID);


CREATE INDEX IFK_Rel_09 ON tbl_DocKey (tbl_keyType_ID);


CREATE TABLE tbl_RoleRight (
  ID BIGSERIAL   NOT NULL ,
  tbl_Right_ID BIGSERIAL   NOT NULL ,
  tbl_Role_ID BIGSERIAL   NOT NULL   ,
PRIMARY KEY(ID)    ,
  FOREIGN KEY(tbl_Role_ID)
    REFERENCES tbl_Role(ID),
  FOREIGN KEY(tbl_Right_ID)
    REFERENCES tbl_Right(ID));


CREATE INDEX tbl_RoleRight_FKIndex1 ON tbl_RoleRight (tbl_Role_ID);
CREATE INDEX tbl_RoleRight_FKIndex2 ON tbl_RoleRight (tbl_Right_ID);


CREATE INDEX IFK_Rel_02 ON tbl_RoleRight (tbl_Role_ID);
CREATE INDEX IFK_Rel_03 ON tbl_RoleRight (tbl_Right_ID);


CREATE TABLE tbl_Doc (
  ID BIGSERIAL   NOT NULL ,
  tbl_User_ID BIGSERIAL   NOT NULL   ,
PRIMARY KEY(ID)  ,
  FOREIGN KEY(tbl_User_ID)
    REFERENCES tbl_User(ID));


CREATE INDEX tbl_Doc_FKIndex1 ON tbl_Doc (tbl_User_ID);


CREATE INDEX IFK_Rel_05 ON tbl_Doc (tbl_User_ID);


CREATE TABLE tbl_GroupKey (
  ID BIGSERIAL   NOT NULL ,
  tbl_keyType_ID BIGSERIAL   NOT NULL ,
  tbl_Doc_ID BIGSERIAL   NOT NULL ,
  keyData BYTEA   NOT NULL ,
  keyIv BYTEA   NOT NULL   ,
PRIMARY KEY(ID)    ,
  FOREIGN KEY(tbl_Doc_ID)
    REFERENCES tbl_Doc(ID),
  FOREIGN KEY(tbl_keyType_ID)
    REFERENCES tbl_keyType(ID));


CREATE INDEX tbl_DocKey_FKIndex1 ON tbl_GroupKey (tbl_Doc_ID);
CREATE INDEX tbl_GroupKey_FKIndex2 ON tbl_GroupKey (tbl_keyType_ID);


CREATE INDEX IFK_Rel_04 ON tbl_GroupKey (tbl_Doc_ID);
CREATE INDEX IFK_Rel_08 ON tbl_GroupKey (tbl_keyType_ID);


CREATE TABLE tbl_GroupDocKey (
  ID BIGSERIAL   NOT NULL ,
  tbl_DocKey_ID BIGSERIAL   NOT NULL ,
  tbl_GroupKey_ID BIGSERIAL   NOT NULL   ,
PRIMARY KEY(ID)    ,
  FOREIGN KEY(tbl_GroupKey_ID)
    REFERENCES tbl_GroupKey(ID),
  FOREIGN KEY(tbl_DocKey_ID)
    REFERENCES tbl_DocKey(ID));


CREATE INDEX tbl_GroupDocKey_FKIndex1 ON tbl_GroupDocKey (tbl_GroupKey_ID);
CREATE INDEX tbl_GroupDocKey_FKIndex2 ON tbl_GroupDocKey (tbl_DocKey_ID);


CREATE INDEX IFK_Rel_06 ON tbl_GroupDocKey (tbl_GroupKey_ID);
CREATE INDEX IFK_Rel_07 ON tbl_GroupDocKey (tbl_DocKey_ID);


CREATE TABLE tbl_RoleGroup (
  ID BIGSERIAL   NOT NULL ,
  tbl_GroupKey_ID BIGSERIAL   NOT NULL ,
  tbl_Role_ID BIGSERIAL   NOT NULL   ,
PRIMARY KEY(ID)    ,
  FOREIGN KEY(tbl_Role_ID)
    REFERENCES tbl_Role(ID),
  FOREIGN KEY(tbl_GroupKey_ID)
    REFERENCES tbl_GroupKey(ID));


CREATE INDEX tbl_RoleGroup_FKIndex1 ON tbl_RoleGroup (tbl_Role_ID);
CREATE INDEX tbl_RoleGroup_FKIndex2 ON tbl_RoleGroup (tbl_GroupKey_ID);


CREATE INDEX IFK_Rel_10 ON tbl_RoleGroup (tbl_Role_ID);
CREATE INDEX IFK_Rel_11 ON tbl_RoleGroup (tbl_GroupKey_ID);


