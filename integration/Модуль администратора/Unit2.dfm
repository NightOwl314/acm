object DataModule2: TDataModule2
  OldCreateOrder = False
  Left = 302
  Top = 55
  Height = 560
  Width = 1030
  object Acm: TIBDatabase
    Connected = True
    DatabaseName = 'C:\acm\db\acm.GDB'
    Params.Strings = (
      'user_name=sysdba'
      'password=avtfbpas')
    LoginPrompt = False
    DefaultTransaction = IBTransaction1
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 16
  end
  object IBTransaction1: TIBTransaction
    Active = True
    DefaultDatabase = Acm
    DefaultAction = TACommitRetaining
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 112
    Top = 16
  end
  object IBDS1: TDataSource
    DataSet = IBDataSet1
    Left = 40
    Top = 144
  end
  object IBDataSet1: TIBDataSet
    Database = Acm
    Transaction = IBTransaction1
    BufferChunks = 1000
    CachedUpdates = False
    SelectSQL.Strings = (
      
        'select TEMA_LNG.NAME as TEMA, TEMA.ID_MOODLE_COURSE  from TEMA, ' +
        'TEMA_LNG where (TEMA_LNG.ID_TM=TEMA.ID_TM) and (TEMA_LNG.ID_LNG=' +
        #39'ru'#39') order by TEMA_LNG.NAME')
    Active = True
    Left = 40
    Top = 88
    object IBDataSet1TEMA: TIBStringField
      FieldName = 'TEMA'
      Origin = 'TEMA_LNG.NAME'
      FixedChar = True
      Size = 50
    end
    object IBDataSet1ID_MOODLE_COURSE: TIntegerField
      FieldName = 'ID_MOODLE_COURSE'
      Origin = 'TEMA.ID_MOODLE_COURSE'
      Required = True
    end
  end
  object IBDataSet2: TIBDataSet
    Database = Acm
    Transaction = IBTransaction1
    BufferChunks = 1000
    CachedUpdates = False
    SelectSQL.Strings = (
      
        'select PROBLEMS_LNG.NAME as PROBLEMA, PROBLEMS.ID_MOODLE_COURSE ' +
        ' from PROBLEMS, PROBLEMS_LNG where (PROBLEMS_LNG.ID_PRB=PROBLEMS' +
        '.ID_PRB) and (PROBLEMS_LNG.ID_LNG='#39'ru'#39') order by PROBLEMS_LNG.NA' +
        'ME')
    Active = True
    Left = 112
    Top = 88
    object IBDataSet2PROBLEMA: TIBStringField
      FieldName = 'PROBLEMA'
      Origin = 'PROBLEMS_LNG.NAME'
      FixedChar = True
      Size = 80
    end
    object IBDataSet2ID_MOODLE_COURSE: TIntegerField
      FieldName = 'ID_MOODLE_COURSE'
      Origin = 'PROBLEMS.ID_MOODLE_COURSE'
      Required = True
    end
  end
  object IBDS2: TDataSource
    DataSet = IBDataSet2
    Left = 112
    Top = 144
  end
  object ADOConnection1: TADOConnection
    Connected = True
    ConnectionString = 
      'Provider=MSDASQL.1;Extended Properties="DATABASE=moodle;DRIVER={' +
      'MySQL ODBC 3.51 Driver};OPTION=3;PWD=mysqldbpas;PORT=3306;SERVER' +
      '=localhost;UID=root;STMT=SET CHARACTER SET cp1251;"'
    LoginPrompt = False
    Left = 488
    Top = 16
  end
  object ADODataSet1: TADODataSet
    Active = True
    Connection = ADOConnection1
    CursorType = ctStatic
    CommandText = 
      'select id as ID_MOODLE_COURSE, fullname as COURSE from mdl_cours' +
      'e'
    Parameters = <>
    Left = 488
    Top = 88
    object ADODataSet1ID_MOODLE_COURSE: TLargeintField
      FieldName = 'ID_MOODLE_COURSE'
    end
    object ADODataSet1COURSE: TStringField
      FieldName = 'COURSE'
      Size = 254
    end
  end
  object ADODS1: TDataSource
    DataSet = ADODataSet1
    Left = 488
    Top = 144
  end
  object IBDataSet3: TIBDataSet
    Database = Acm
    Transaction = IBTransaction1
    AfterOpen = FetchAllIBDataSet3
    BufferChunks = 1000
    CachedUpdates = False
    SelectSQL.Strings = (
      
        'select TEMA_LNG.NAME from TEMA, TEMA_LNG where (TEMA_LNG.ID_TM=T' +
        'EMA.ID_TM) and (TEMA_LNG.ID_LNG='#39'ru'#39') order by TEMA_LNG.NAME')
    Active = True
    Left = 192
    Top = 88
    object IBDataSet3NAME: TIBStringField
      FieldName = 'NAME'
      Origin = 'TEMA_LNG.NAME'
      FixedChar = True
      Size = 50
    end
  end
  object IBDS3: TDataSource
    DataSet = IBDataSet3
    Left = 192
    Top = 144
  end
  object ADODataSet2: TADODataSet
    Active = True
    Connection = ADOConnection1
    CursorType = ctStatic
    CommandText = 'select fullname from mdl_course order by id'
    Parameters = <>
    Left = 568
    Top = 88
    object ADODataSet2fullname: TStringField
      FieldName = 'fullname'
      Size = 254
    end
  end
  object ADODS2: TDataSource
    DataSet = ADODataSet2
    Left = 568
    Top = 144
  end
  object IBQuery1: TIBQuery
    Database = Acm
    Transaction = IBTransaction2
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      
        'update TEMA set ID_MOODLE_COURSE=:p2 where ID_TM=(select ID_TM f' +
        'rom TEMA_LNG where TEMA_LNG.NAME=:p3 and TEMA_LNG.ID_LNG='#39'ru'#39')')
    Left = 336
    Top = 88
    ParamData = <
      item
        DataType = ftInteger
        Name = 'p2'
        ParamType = ptInputOutput
      end
      item
        DataType = ftString
        Name = 'p3'
        ParamType = ptInputOutput
      end>
  end
  object ADOQuery1: TADOQuery
    Connection = ADOConnection1
    CursorType = ctStatic
    Parameters = <
      item
        Name = 'p1'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end>
    SQL.Strings = (
      'select id from mdl_course where fullname=:p1')
    Left = 648
    Top = 88
  end
  object IBQuery2: TIBQuery
    Database = Acm
    Transaction = IBTransaction3
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      
        'update PROBLEMS set ID_MOODLE_COURSE=:p5 where ID_PRB=(select ID' +
        '_PRB from PROBLEMS_LNG where PROBLEMS_LNG.NAME=:p6 and PROBLEMS_' +
        'LNG.ID_LNG='#39'ru'#39')')
    Left = 408
    Top = 88
    ParamData = <
      item
        DataType = ftInteger
        Name = 'p5'
        ParamType = ptInputOutput
      end
      item
        DataType = ftString
        Name = 'p6'
        ParamType = ptInputOutput
      end>
  end
  object ADOQuery2: TADOQuery
    Connection = ADOConnection1
    CursorType = ctStatic
    Parameters = <
      item
        Name = 'p4'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end>
    SQL.Strings = (
      'select id from mdl_course where fullname=:p4')
    Left = 728
    Top = 88
  end
  object IBDataSet4: TIBDataSet
    Database = Acm
    Transaction = IBTransaction1
    AfterOpen = FetchAllIBDataSet4
    BufferChunks = 1000
    CachedUpdates = False
    SelectSQL.Strings = (
      
        'select PROBLEMS_LNG.NAME from PROBLEMS, PROBLEMS_LNG where (PROB' +
        'LEMS_LNG.ID_PRB=PROBLEMS.ID_PRB) and (PROBLEMS_LNG.ID_LNG='#39'ru'#39') ' +
        'order by PROBLEMS_LNG.NAME')
    Active = True
    Left = 264
    Top = 88
    object IBDataSet4NAME: TIBStringField
      FieldName = 'NAME'
      Origin = 'PROBLEMS_LNG.NAME'
      FixedChar = True
      Size = 80
    end
  end
  object IBDS4: TDataSource
    DataSet = IBDataSet4
    Left = 264
    Top = 144
  end
  object ADODataSet3: TADODataSet
    Active = True
    Connection = ADOConnection1
    CursorType = ctStatic
    CommandText = 
      'select mdl_course.fullname as COURSE, mdl_course_sections.sectio' +
      'n as NOMER_SECTION, mdl_course_sections.ID_PS_TEMA  from mdl_cou' +
      'rse,mdl_course_sections where mdl_course.id=mdl_course_sections.' +
      'course'
    Parameters = <>
    Left = 488
    Top = 224
    object ADODataSet3COURSE: TStringField
      FieldName = 'COURSE'
      Size = 254
    end
    object ADODataSet3ID_PS_TEMA: TIntegerField
      FieldName = 'ID_PS_TEMA'
    end
    object ADODataSet3NOMER_SECTION: TLargeintField
      FieldName = 'NOMER_SECTION'
    end
  end
  object ADODS3: TDataSource
    DataSet = ADODataSet3
    Left = 488
    Top = 280
  end
  object IBDataSet5: TIBDataSet
    Database = Acm
    Transaction = IBTransaction1
    AfterOpen = FetchAllIBDataSet4
    BufferChunks = 1000
    CachedUpdates = False
    SelectSQL.Strings = (
      
        'select TEMA.ID_TM as ID_PS_TEMA, TEMA_LNG.NAME as TEMA from TEMA' +
        ', TEMA_LNG where (TEMA_LNG.ID_TM=TEMA.ID_TM) and (TEMA_LNG.ID_LN' +
        'G='#39'ru'#39') order by TEMA.ID_TM')
    Active = True
    Left = 40
    Top = 224
    object IBDataSet5TEMA: TIBStringField
      FieldName = 'TEMA'
      Origin = 'TEMA_LNG.NAME'
      FixedChar = True
      Size = 50
    end
    object IBDataSet5ID_PS_TEMA: TIntegerField
      FieldName = 'ID_PS_TEMA'
      Origin = 'TEMA.ID_TM'
      Required = True
    end
  end
  object IBDS5: TDataSource
    DataSet = IBDataSet5
    Left = 40
    Top = 280
  end
  object ADODS4: TDataSource
    DataSet = ADODataSet4
    Left = 568
    Top = 280
  end
  object ADODataSet4: TADODataSet
    Connection = ADOConnection1
    CursorType = ctStatic
    CommandText = 
      'select mdl_course_sections.section from mdl_course_sections, mdl' +
      '_course where (mdl_course.fullname=:a1) and (mdl_course_sections' +
      '.course=mdl_course.id)'
    Parameters = <
      item
        Name = 'a1'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end>
    Left = 568
    Top = 224
    object ADODataSet4section: TLargeintField
      FieldName = 'section'
    end
  end
  object IBQuery3: TIBQuery
    Database = Acm
    Transaction = IBTransaction1
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      
        'select TEMA.ID_TM from TEMA, TEMA_LNG where TEMA.ID_TM=TEMA_LNG.' +
        'ID_TM and TEMA_LNG.ID_LNG='#39'ru'#39' and TEMA_LNG.NAME=:a2')
    Left = 184
    Top = 224
    ParamData = <
      item
        DataType = ftString
        Name = 'a2'
        ParamType = ptInput
      end>
    object IBQuery3ID_TM: TIntegerField
      FieldName = 'ID_TM'
      Origin = 'TEMA.ID_TM'
      Required = True
    end
  end
  object ADOQuery3: TADOQuery
    Connection = ADOConnection1
    CursorType = ctStatic
    Parameters = <
      item
        Name = 'a3'
        Attributes = [paNullable]
        DataType = ftInteger
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'a4'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'a5'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end>
    SQL.Strings = (
      'update mdl_course_sections'
      'set ID_PS_TEMA=:a3 '
      'where course=(select id from mdl_course where fullname=:a4) '
      'and section=:a5')
    Left = 648
    Top = 224
  end
  object IBDataSet6: TIBDataSet
    Database = Acm
    Transaction = IBTransaction1
    AfterOpen = FetchAllIBDataSet6
    BufferChunks = 1000
    CachedUpdates = False
    SelectSQL.Strings = (
      
        'select TEMA_LNG.NAME from TEMA, TEMA_LNG where (TEMA_LNG.ID_TM=T' +
        'EMA.ID_TM) and (TEMA_LNG.ID_LNG='#39'ru'#39') order by TEMA_LNG.ID_TM')
    Active = True
    Left = 112
    Top = 224
    object IBStringField1: TIBStringField
      FieldName = 'NAME'
      Origin = 'TEMA_LNG.NAME'
      FixedChar = True
      Size = 50
    end
  end
  object IBDS6: TDataSource
    DataSet = IBDataSet6
    Left = 112
    Top = 280
  end
  object ADODS7: TDataSource
    DataSet = ADODataSet7
    Left = 648
    Top = 408
  end
  object ADODataSet7: TADODataSet
    Active = True
    Connection = ADOConnection1
    CursorType = ctStatic
    CommandText = 
      'select mdl_assignment.name '#13#10'from mdl_assignment'#13#10'where mdl_assi' +
      'gnment.id in'#13#10'(select mdl_course_modules.instance '#13#10'from mdl_cou' +
      'rse_sections, mdl_course_modules, mdl_course'#13#10'where (mdl_course.' +
      'fullname=:b1) '#13#10'and (mdl_course_sections.section=:b2) '#13#10'and (mdl' +
      '_course.id=mdl_course_modules.course) '#13#10'and (mdl_course_sections' +
      '.id=mdl_course_modules.section)'#13#10'and (mdl_course_modules.module=' +
      #39'1'#39'))'#13#10
    Parameters = <
      item
        Name = 'b1'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'b2'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end>
    Left = 648
    Top = 352
    object ADODataSet7name: TStringField
      FieldName = 'name'
      Size = 255
    end
  end
  object ADODS5: TDataSource
    DataSet = ADODataSet5
    Left = 488
    Top = 408
  end
  object ADODataSet5: TADODataSet
    Connection = ADOConnection1
    CursorType = ctStatic
    CommandText = 
      'select distinct mdl_user.firstname'#13#10'from mdl_user,mdl_role, mdl_' +
      'role_assignments,mdl_context,mdl_course '#13#10'where mdl_user.id=mdl_' +
      'role_assignments.userid'#13#10'and mdl_role.id=mdl_role_assignments.ro' +
      'leid'#13#10'and mdl_role.id=5'#13#10'and mdl_course.id=mdl_context.instancei' +
      'd'#13#10'and mdl_context.contextlevel=50'#13#10'and mdl_role_assignments.con' +
      'textid=mdl_context.id'#13#10'and mdl_course.fullname=:x1'#13#10
    Parameters = <
      item
        Name = 'x1'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end>
    Left = 488
    Top = 352
    object ADODataSet5firstname: TStringField
      FieldName = 'firstname'
      Size = 100
    end
  end
  object ADODS6: TDataSource
    DataSet = ADODataSet6
    Left = 568
    Top = 408
  end
  object ADODataSet6: TADODataSet
    Connection = ADOConnection1
    CursorType = ctStatic
    CommandText = 
      'select mdl_user.lastname'#13#10'from mdl_user,mdl_role, mdl_role_assig' +
      'nments,mdl_context,mdl_course '#13#10'where mdl_user.id=mdl_role_assig' +
      'nments.userid'#13#10'and mdl_role.id=mdl_role_assignments.roleid'#13#10'and ' +
      'mdl_role.id=5'#13#10'and mdl_course.id=mdl_context.instanceid'#13#10'and mdl' +
      '_context.contextlevel=50'#13#10'and mdl_role_assignments.contextid=mdl' +
      '_context.id'#13#10'and mdl_course.fullname=:x1'#13#10'and mdl_user.firstname' +
      '=:x2'#13#10#13#10#13#10
    Parameters = <
      item
        Name = 'x1'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'x2'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end>
    Left = 568
    Top = 352
    object ADODataSet6lastname: TStringField
      FieldName = 'lastname'
      Size = 100
    end
  end
  object ADODS8: TDataSource
    DataSet = ADODataSet8
    Left = 728
    Top = 408
  end
  object ADODataSet8: TADODataSet
    Active = True
    Connection = ADOConnection1
    CursorType = ctStatic
    CommandText = 
      'select mdl_course.fullname as COURSE, mdl_course_sections.sectio' +
      'n as NOMER_SECTION, mdl_assignment.name as DANNYE, mdl_user.firs' +
      'tname as SURNAME, mdl_user.lastname as NAME'#13#10'from mdl_assignment' +
      ', mdl_course_sections, mdl_course_modules, mdl_course, mdl_user,' +
      ' mdl_assignment_submissions'#13#10'where (mdl_course.id=mdl_course_mod' +
      'ules.course) '#13#10'and (mdl_course_sections.id=mdl_course_modules.se' +
      'ction)'#13#10'and (mdl_course_modules.module='#39'1'#39')'#13#10'and (mdl_assignment' +
      '.id=mdl_course_modules.instance)'#13#10'and (mdl_assignment.id=mdl_ass' +
      'ignment_submissions.assignment)'#13#10'and (mdl_assignment_submissions' +
      '.userid=mdl_user.id)'#13#10'order by COURSE,NOMER_SECTION,DANNYE,SURNA' +
      'ME'
    Parameters = <>
    Left = 728
    Top = 352
    object ADODataSet8COURSE: TStringField
      FieldName = 'COURSE'
      Size = 254
    end
    object ADODataSet8NOMER_SECTION: TLargeintField
      FieldName = 'NOMER_SECTION'
    end
    object ADODataSet8DANNYE: TStringField
      FieldName = 'DANNYE'
      Size = 255
    end
    object ADODataSet8SURNAME: TStringField
      FieldName = 'SURNAME'
      Size = 100
    end
    object ADODataSet8NAME: TStringField
      FieldName = 'NAME'
      Size = 100
    end
  end
  object ADOQuery4: TADOQuery
    Connection = ADOConnection1
    CursorType = ctStatic
    Parameters = <
      item
        Name = 'c1'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'c2'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'c3'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'c4'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'c5'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end>
    SQL.Strings = (
      'select count(mdl_assignment_submissions.id) as count'
      'from mdl_assignment, mdl_course_sections, mdl_course_modules, '
      'mdl_course, mdl_user, mdl_assignment_submissions'
      'where (mdl_course.id=mdl_course_modules.course) '
      'and (mdl_course_sections.id=mdl_course_modules.section)'
      'and (mdl_course_modules.module='#39'1'#39')'
      'and (mdl_assignment.id=mdl_course_modules.instance)'
      'and (mdl_assignment.id=mdl_assignment_submissions.assignment)'
      'and (mdl_assignment_submissions.userid=mdl_user.id)'
      'and (mdl_user.firstname=:c1) '
      'and (mdl_user.lastname=:c2) '
      'and (mdl_course.fullname=:c3)'
      'and (mdl_course_sections.section=:c4)'
      'and (mdl_assignment.name=:c5)')
    Left = 496
    Top = 464
    object ADOQuery4count: TLargeintField
      FieldName = 'count'
      ReadOnly = True
    end
  end
  object ADOQuery5: TADOQuery
    Connection = ADOConnection1
    CursorType = ctStatic
    Parameters = <>
    SQL.Strings = (
      'select max(id) as id from mdl_assignment_submissions')
    Left = 568
    Top = 464
    object ADOQuery5id: TLargeintField
      FieldName = 'id'
      ReadOnly = True
    end
  end
  object ADOQuery6: TADOQuery
    Connection = ADOConnection1
    CursorType = ctStatic
    Parameters = <
      item
        Name = 'c3'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'c4'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'c5'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end>
    SQL.Strings = (
      'select mdl_assignment.id as assignment '
      
        'from mdl_assignment, mdl_course_sections, mdl_course_modules, md' +
        'l_course '
      'where (mdl_course.id=mdl_course_modules.course) '
      'and (mdl_course_sections.id=mdl_course_modules.section) '
      'and (mdl_course_modules.module=1) '
      'and (mdl_assignment.id=mdl_course_modules.instance) '
      'and (mdl_course.fullname=:c3) '
      'and (mdl_course_sections.section=:c4) '
      'and (mdl_assignment.name=:c5)')
    Left = 648
    Top = 464
    object ADOQuery6assignment: TLargeintField
      FieldName = 'assignment'
    end
  end
  object ADOQuery7: TADOQuery
    Connection = ADOConnection1
    CursorType = ctStatic
    Parameters = <
      item
        Name = 'c1'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'c2'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end>
    SQL.Strings = (
      
        'select id as userid from mdl_user where firstname=:c1 and lastna' +
        'me=:c2')
    Left = 728
    Top = 464
    object ADOQuery7userid: TLargeintField
      FieldName = 'userid'
    end
  end
  object ADOQuery8: TADOQuery
    Connection = ADOConnection1
    CursorType = ctStatic
    Parameters = <
      item
        Name = 'z1'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'z2'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'z3'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'z4'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end>
    SQL.Strings = (
      
        'insert into mdl_assignment_submissions (id,assignment,userid,dat' +
        'a1,data2,grade,submissioncomment) VALUES (:z1,:z2,:z3,:z4,'#39'1'#39',-1' +
        ','#39#39')')
    Left = 808
    Top = 464
  end
  object ADOQuery9: TADOQuery
    Connection = ADOConnection1
    CursorType = ctStatic
    Parameters = <
      item
        Name = 'z4'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'z2'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end
      item
        Name = 'z3'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end>
    SQL.Strings = (
      'update mdl_assignment_submissions '
      'set data1=:z4'
      'where (assignment=:z2)'
      'and (userid=:z3)')
    Left = 888
    Top = 464
  end
  object IBDataSet8: TIBDataSet
    Database = Acm
    Transaction = IBTransaction1
    BufferChunks = 1000
    CachedUpdates = False
    SelectSQL.Strings = (
      'select count(TM_PRB.ID_PRB) as obkolvo'
      'from TEMA,TEMA_LNG,TM_PRB '
      'where TEMA.ID_TM=TM_PRB.ID_TM'
      'and TEMA.ID_TM=TEMA_LNG.ID_TM '
      'and TEMA_LNG.ID_LNG='#39'ru'#39' '
      'and TEMA_LNG.NAME=:q1')
    Left = 40
    Top = 352
    object IBDataSet8OBKOLVO: TIntegerField
      FieldName = 'OBKOLVO'
      Required = True
    end
  end
  object IBDS8: TDataSource
    DataSet = IBDataSet8
    Left = 40
    Top = 408
  end
  object IBDataSet9: TIBDataSet
    Database = Acm
    Transaction = IBTransaction1
    BufferChunks = 1000
    CachedUpdates = False
    SelectSQL.Strings = (
      'select count(ID_PRB)  as kolvoresh'
      'from PROBLEMS'
      'where ID_PRB in (select distinct STATUS.ID_PRB'
      'from TEMA,TEMA_LNG,TM_PRB,STATUS,AUTHORS '
      'where TEMA.ID_TM=TM_PRB.ID_TM'
      'and TEMA.ID_TM=TEMA_LNG.ID_TM '
      'and TEMA_LNG.ID_LNG='#39'ru'#39' '
      'and STATUS.ID_RSL=0'
      'and STATUS.ID_PUBL=AUTHORS.ID_PUBL'
      'and STATUS.ID_PRB=TM_PRB.ID_PRB'
      'and AUTHORS.SURNAME=:v1'
      'and AUTHORS.UNAME=:v2'
      'and TEMA_LNG.NAME=:v3)')
    Left = 112
    Top = 352
    object IBDataSet9KOLVORESH: TIntegerField
      FieldName = 'KOLVORESH'
      Required = True
    end
  end
  object IBDS9: TDataSource
    DataSet = IBDataSet9
    Left = 112
    Top = 408
  end
  object IBDataSet10: TIBDataSet
    Database = Acm
    Transaction = IBTransaction1
    BufferChunks = 1000
    CachedUpdates = False
    SelectSQL.Strings = (
      'select count(ID_PRB)  as kolvoneresh'
      'from PROBLEMS'
      'where ID_PRB in (select distinct STATUS.ID_PRB'
      'from TEMA,TEMA_LNG,TM_PRB,STATUS,AUTHORS '
      'where TEMA.ID_TM=TM_PRB.ID_TM'
      'and TEMA.ID_TM=TEMA_LNG.ID_TM '
      'and TEMA_LNG.ID_LNG='#39'ru'#39' '
      'and STATUS.ID_RSL=0'
      'and STATUS.ID_PUBL=AUTHORS.ID_PUBL'
      'and STATUS.ID_PRB=TM_PRB.ID_PRB'
      'and AUTHORS.NAME=:v4'
      'and TEMA_LNG.NAME=:v5)')
    Left = 184
    Top = 352
    object IBDataSet10KOLVONERESH: TIntegerField
      FieldName = 'KOLVONERESH'
      Required = True
    end
  end
  object IBDS10: TDataSource
    DataSet = IBDataSet10
    Left = 184
    Top = 408
  end
  object ADOQuery10: TADOQuery
    Connection = ADOConnection1
    CursorType = ctStatic
    Parameters = <
      item
        Name = 'e1'
        Attributes = [paNullable]
        DataType = ftString
        Precision = 255
        Size = 255
        Value = Null
      end>
    SQL.Strings = (
      'select mdl_user.firstname, mdl_user.lastname'
      
        'from mdl_user,mdl_role, mdl_role_assignments,mdl_context,mdl_cou' +
        'rse '
      'where mdl_user.id=mdl_role_assignments.userid'
      'and mdl_role.id=mdl_role_assignments.roleid'
      'and mdl_role.id=5'
      'and mdl_course.id=mdl_context.instanceid'
      'and mdl_context.contextlevel=50'
      'and mdl_role_assignments.contextid=mdl_context.id'
      'and mdl_course.fullname=:e1')
    Left = 960
    Top = 464
  end
  object IBTransaction2: TIBTransaction
    Active = True
    DefaultDatabase = Acm
    DefaultAction = TACommitRetaining
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 192
    Top = 16
  end
  object IBTransaction3: TIBTransaction
    Active = True
    DefaultDatabase = Acm
    DefaultAction = TACommitRetaining
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 272
    Top = 16
  end
end
