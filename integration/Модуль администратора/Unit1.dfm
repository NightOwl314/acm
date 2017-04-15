object Form1: TForm1
  Left = 237
  Top = 134
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 
    #1052#1086#1076#1091#1083#1100' '#1072#1076#1084#1080#1085#1080#1089#1090#1088#1072#1090#1086#1088#1072' '#1076#1083#1103' '#1080#1085#1090#1077#1075#1088#1072#1094#1080#1080' '#1057#1044#1054' Moodle '#1089' '#1087#1088#1086#1074#1077#1088#1103#1102#1097#1077#1081' '#1089#1080 +
    #1089#1090#1077#1084#1086#1081' '#1082#1072#1092#1077#1076#1088#1099' '#1040#1042#1058
  ClientHeight = 537
  ClientWidth = 866
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 865
    Height = 537
    ActivePage = TabSheet1
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = #1048#1085#1090#1077#1075#1088#1072#1094#1080#1103' '#1055#1057' '#1089' Moodle'
      object Label1: TLabel
        Left = 144
        Top = 16
        Width = 200
        Height = 23
        Caption = #1055#1088#1086#1074#1077#1088#1103#1102#1097#1072#1103' '#1089#1080#1089#1090#1077#1084#1072
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = []
        ParentFont = False
      end
      object Label2: TLabel
        Left = 616
        Top = 16
        Width = 113
        Height = 23
        Caption = #1057#1044#1054' Moodle'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = []
        ParentFont = False
      end
      object Label3: TLabel
        Left = 56
        Top = 320
        Width = 724
        Height = 23
        Caption = 
          #1059#1089#1090#1072#1085#1086#1074#1082#1072' '#1089#1086#1086#1090#1074#1077#1090#1089#1090#1074#1080#1103' '#1084#1077#1078#1076#1091'  '#1090#1077#1084#1086#1081' '#1074' '#1087#1088#1086#1074#1077#1088#1103#1102#1097#1077#1081' '#1089#1080#1089#1090#1077#1084#1077' '#1080' '#1082#1091#1088#1089 +
          #1086#1084' '#1074' Moodle'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = []
        ParentFont = False
      end
      object Label4: TLabel
        Left = 56
        Top = 416
        Width = 739
        Height = 23
        Caption = 
          #1059#1089#1090#1072#1085#1086#1074#1082#1072' '#1089#1086#1086#1090#1074#1077#1090#1089#1090#1074#1080#1103' '#1084#1077#1078#1076#1091'  '#1079#1072#1076#1072#1095#1077#1081' '#1074' '#1087#1088#1086#1074#1077#1088#1103#1102#1097#1077#1081' '#1089#1080#1089#1090#1077#1084#1077' '#1080' '#1082#1091 +
          #1088#1089#1086#1084' '#1074' Moodle'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = []
        ParentFont = False
      end
      object Label5: TLabel
        Left = 56
        Top = 352
        Width = 156
        Height = 13
        Caption = #1058#1077#1084#1072' '#1074' '#1087#1088#1086#1074#1077#1088#1103#1102#1097#1077#1081' '#1089#1080#1089#1090#1077#1084#1077
      end
      object Label6: TLabel
        Left = 408
        Top = 352
        Width = 71
        Height = 13
        Caption = #1050#1091#1088#1089' '#1074' Moodle'
      end
      object Label7: TLabel
        Left = 408
        Top = 448
        Width = 71
        Height = 13
        Caption = #1050#1091#1088#1089' '#1074' Moodle'
      end
      object Label8: TLabel
        Left = 56
        Top = 448
        Width = 165
        Height = 13
        Caption = #1047#1072#1076#1072#1095#1072' '#1074' '#1087#1088#1086#1074#1077#1088#1103#1102#1097#1077#1081' '#1089#1080#1089#1090#1077#1084#1077
      end
      object DBGrid1: TDBGrid
        Left = 32
        Top = 48
        Width = 441
        Height = 113
        DataSource = DataModule2.IBDS1
        ReadOnly = True
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        Columns = <
          item
            Expanded = False
            FieldName = 'TEMA'
            Width = 281
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'ID_MOODLE_COURSE'
            Width = 119
            Visible = True
          end>
      end
      object DBGrid2: TDBGrid
        Left = 32
        Top = 184
        Width = 441
        Height = 113
        DataSource = DataModule2.IBDS2
        ReadOnly = True
        TabOrder = 1
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        Columns = <
          item
            Expanded = False
            FieldName = 'PROBLEMA'
            Width = 282
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'ID_MOODLE_COURSE'
            Visible = True
          end>
      end
      object DBGrid3: TDBGrid
        Left = 520
        Top = 48
        Width = 305
        Height = 249
        DataSource = DataModule2.ADODS1
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        TabOrder = 2
        TitleFont.Charset = RUSSIAN_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        Columns = <
          item
            Expanded = False
            FieldName = 'ID_MOODLE_COURSE'
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'COURSE'
            Width = 151
            Visible = True
          end>
      end
      object DBLookupComboBox1: TDBLookupComboBox
        Left = 56
        Top = 368
        Width = 281
        Height = 21
        HelpType = htKeyword
        HelpKeyword = '0'
        KeyField = 'NAME'
        ListField = 'NAME'
        ListSource = DataModule2.IBDS3
        TabOrder = 3
      end
      object DBLookupComboBox2: TDBLookupComboBox
        Left = 408
        Top = 368
        Width = 161
        Height = 21
        KeyField = 'fullname'
        ListField = 'fullname'
        ListSource = DataModule2.ADODS2
        TabOrder = 4
      end
      object Button1: TButton
        Left = 632
        Top = 368
        Width = 153
        Height = 25
        Caption = #1059#1089#1090#1072#1085#1086#1074#1080#1090#1100' '#1089#1086#1086#1090#1074#1077#1090#1089#1090#1074#1080#1077
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 5
        OnClick = Button1Click
      end
      object DBLookupComboBox3: TDBLookupComboBox
        Left = 56
        Top = 464
        Width = 281
        Height = 21
        HelpType = htKeyword
        HelpKeyword = '0'
        KeyField = 'NAME'
        ListField = 'NAME'
        ListSource = DataModule2.IBDS4
        TabOrder = 6
      end
      object DBLookupComboBox4: TDBLookupComboBox
        Left = 408
        Top = 464
        Width = 161
        Height = 21
        KeyField = 'fullname'
        ListField = 'fullname'
        ListSource = DataModule2.ADODS2
        TabOrder = 7
      end
      object Button2: TButton
        Left = 632
        Top = 464
        Width = 153
        Height = 25
        Caption = #1059#1089#1090#1072#1085#1086#1074#1080#1090#1100' '#1089#1086#1086#1090#1074#1077#1090#1089#1090#1074#1080#1077
        TabOrder = 8
        OnClick = Button2Click
      end
    end
    object TabSheet2: TTabSheet
      Caption = #1048#1085#1090#1077#1075#1088#1072#1094#1080#1103' Moodle '#1089' '#1055#1057
      ImageIndex = 1
      object Label9: TLabel
        Left = 144
        Top = 16
        Width = 113
        Height = 23
        Caption = #1057#1044#1054' Moodle'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = []
        ParentFont = False
      end
      object Label10: TLabel
        Left = 528
        Top = 16
        Width = 200
        Height = 23
        Caption = #1055#1088#1086#1074#1077#1088#1103#1102#1097#1072#1103' '#1089#1080#1089#1090#1077#1084#1072
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = []
        ParentFont = False
      end
      object Label11: TLabel
        Left = 16
        Top = 368
        Width = 822
        Height = 13
        Caption = 
          #1047#1085#1072#1095#1077#1085#1080#1077' '#1074' '#1087#1086#1083#1077' ID_PS_TEMA=-1 '#1074' Moodle '#1075#1086#1074#1086#1088#1080#1090' '#1086' '#1090#1086#1084', '#1095#1090#1086' '#1087#1088#1080' '#1087#1077 +
          #1088#1077#1093#1086#1076#1077' '#1080#1079' Moodle '#1074' '#1087#1088#1086#1074#1077#1088#1103#1102#1097#1091#1102' '#1089#1080#1089#1090#1077#1084#1091' '#1087#1077#1088#1077#1093#1086#1076' '#1073#1091#1076#1077#1090' '#1086#1089#1091#1097#1077#1089#1090#1074#1083#1077#1085 +
          ' '#1085#1072' '#1075#1083#1072#1074#1085#1091#1102' '#1089#1090#1088#1072#1085#1080#1094#1091'!'
      end
      object Label12: TLabel
        Left = 40
        Top = 408
        Width = 779
        Height = 23
        Caption = 
          #1059#1089#1090#1072#1085#1086#1074#1082#1072' '#1089#1086#1086#1090#1074#1077#1090#1089#1090#1074#1080#1103' '#1084#1077#1078#1076#1091' '#1089#1077#1082#1094#1080#1077#1081' '#1082#1091#1088#1089#1072' '#1074' Moodle '#1080' '#1090#1077#1084#1086#1081' '#1074' '#1087#1088 +
          #1086#1074#1077#1088#1103#1102#1097#1077#1081' '#1089#1080#1089#1090#1077#1084#1077
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = []
        ParentFont = False
      end
      object Label13: TLabel
        Left = 24
        Top = 448
        Width = 71
        Height = 13
        Caption = #1050#1091#1088#1089' '#1074' Moodle'
      end
      object Label14: TLabel
        Left = 368
        Top = 448
        Width = 156
        Height = 13
        Caption = #1058#1077#1084#1072' '#1074' '#1087#1088#1086#1074#1077#1088#1103#1102#1097#1077#1081' '#1089#1080#1089#1090#1077#1084#1077
      end
      object Label15: TLabel
        Left = 216
        Top = 448
        Width = 114
        Height = 13
        Caption = #1053#1086#1084#1077#1088' '#1089#1077#1082#1094#1080#1080' '#1074' '#1082#1091#1088#1089#1077
      end
      object DBGrid4: TDBGrid
        Left = 40
        Top = 48
        Width = 345
        Height = 297
        DataSource = DataModule2.ADODS3
        ReadOnly = True
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        Columns = <
          item
            Expanded = False
            FieldName = 'COURSE'
            Width = 137
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'NOMER_SECTION'
            Width = 98
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'ID_PS_TEMA'
            Width = 73
            Visible = True
          end>
      end
      object DBGrid5: TDBGrid
        Left = 424
        Top = 48
        Width = 393
        Height = 297
        DataSource = DataModule2.IBDS5
        ReadOnly = True
        TabOrder = 1
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        Columns = <
          item
            Expanded = False
            FieldName = 'ID_PS_TEMA'
            Width = 73
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'TEMA'
            Width = 284
            Visible = True
          end>
      end
      object DBLookupComboBox5: TDBLookupComboBox
        Left = 24
        Top = 464
        Width = 161
        Height = 21
        KeyField = 'fullname'
        ListField = 'fullname'
        ListSource = DataModule2.ADODS2
        TabOrder = 2
        OnCloseUp = DBLookupComboBox5Click
      end
      object DBLookupComboBox6: TDBLookupComboBox
        Left = 216
        Top = 464
        Width = 121
        Height = 21
        Enabled = False
        KeyField = 'section'
        ListField = 'section'
        ListSource = DataModule2.ADODS4
        TabOrder = 3
      end
      object DBLookupComboBox7: TDBLookupComboBox
        Left = 368
        Top = 464
        Width = 281
        Height = 21
        HelpType = htKeyword
        HelpKeyword = '0'
        KeyField = 'NAME'
        ListField = 'NAME'
        ListSource = DataModule2.IBDS6
        TabOrder = 4
      end
      object Button3: TButton
        Left = 680
        Top = 464
        Width = 153
        Height = 25
        Caption = #1059#1089#1090#1072#1085#1086#1074#1080#1090#1100' '#1089#1086#1086#1090#1074#1077#1090#1089#1090#1074#1080#1077
        TabOrder = 5
        OnClick = Button3Click
      end
    end
    object TabSheet3: TTabSheet
      Caption = #1048#1084#1087#1086#1088#1090' '#1076#1072#1085#1085#1099#1093' '#1080#1079' '#1055#1057' '#1074' Moodle'
      ImageIndex = 2
      object Label16: TLabel
        Left = 144
        Top = 224
        Width = 200
        Height = 23
        Caption = #1055#1088#1086#1074#1077#1088#1103#1102#1097#1072#1103' '#1089#1080#1089#1090#1077#1084#1072
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = []
        ParentFont = False
      end
      object Label17: TLabel
        Left = 96
        Top = 256
        Width = 27
        Height = 13
        Caption = #1058#1077#1084#1072
      end
      object Label19: TLabel
        Left = 368
        Top = 56
        Width = 113
        Height = 23
        Caption = #1057#1044#1054' Moodle'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = []
        ParentFont = False
      end
      object Label20: TLabel
        Left = 136
        Top = 16
        Width = 553
        Height = 23
        Caption = #1048#1084#1087#1086#1088#1090' '#1076#1072#1085#1085#1099#1093' '#1086' '#1089#1090#1091#1076#1077#1085#1090#1077' '#1080#1079' '#1087#1088#1086#1074#1077#1088#1103#1102#1097#1077#1081' '#1089#1080#1089#1090#1077#1084#1099' '#1074' Moodle'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = []
        ParentFont = False
      end
      object Label21: TLabel
        Left = 88
        Top = 96
        Width = 24
        Height = 13
        Caption = #1050#1091#1088#1089
      end
      object Label22: TLabel
        Left = 368
        Top = 96
        Width = 114
        Height = 13
        Caption = #1053#1086#1084#1077#1088' '#1089#1077#1082#1094#1080#1080' '#1074' '#1082#1091#1088#1089#1077
      end
      object Label23: TLabel
        Left = 520
        Top = 96
        Width = 244
        Height = 13
        Caption = #1069#1083#1077#1084#1077#1085#1090' '#1082#1091#1088#1089#1072' "'#1047#1072#1076#1072#1085#1080#1077' - '#1054#1090#1074#1077#1090' '#1074' '#1074#1080#1076#1077' '#1090#1077#1082#1089#1090#1072'"'
      end
      object Label24: TLabel
        Left = 176
        Top = 328
        Width = 491
        Height = 23
        Caption = #1044#1072#1085#1085#1099#1077' '#1086' '#1089#1090#1091#1076#1077#1085#1090#1072#1093' '#1080#1079' '#1087#1088#1086#1074#1077#1088#1103#1102#1097#1077#1081' '#1089#1080#1089#1090#1077#1084#1099' '#1074' Moodle'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = []
        ParentFont = False
      end
      object Label25: TLabel
        Left = 448
        Top = 152
        Width = 97
        Height = 13
        Caption = #1060#1072#1084#1080#1083#1080#1103' '#1089#1090#1091#1076#1077#1085#1090#1072
      end
      object Bevel1: TBevel
        Left = 56
        Top = 216
        Width = 385
        Height = 97
        Shape = bsFrame
      end
      object Bevel2: TBevel
        Left = 56
        Top = 48
        Width = 745
        Height = 153
        Shape = bsFrame
      end
      object Label26: TLabel
        Left = 640
        Top = 152
        Width = 70
        Height = 13
        Caption = #1048#1084#1103' '#1089#1090#1091#1076#1077#1085#1090#1072
      end
      object DBLookupComboBox9: TDBLookupComboBox
        Left = 96
        Top = 272
        Width = 305
        Height = 21
        KeyField = 'NAME'
        ListField = 'NAME'
        ListSource = DataModule2.IBDS3
        TabOrder = 0
      end
      object DBLookupComboBox12: TDBLookupComboBox
        Left = 88
        Top = 112
        Width = 249
        Height = 21
        KeyField = 'fullname'
        ListField = 'fullname'
        ListSource = DataModule2.ADODS2
        TabOrder = 1
        OnCloseUp = DBLookupComboBox12Click
      end
      object DBLookupComboBox13: TDBLookupComboBox
        Left = 368
        Top = 112
        Width = 121
        Height = 21
        Enabled = False
        KeyField = 'section'
        ListField = 'section'
        ListSource = DataModule2.ADODS4
        TabOrder = 2
        OnCloseUp = DBLookupComboBox13Click
      end
      object DBLookupComboBox14: TDBLookupComboBox
        Left = 520
        Top = 112
        Width = 249
        Height = 21
        Enabled = False
        KeyField = 'name'
        ListField = 'name'
        ListSource = DataModule2.ADODS7
        TabOrder = 3
      end
      object Button4: TButton
        Left = 528
        Top = 240
        Width = 193
        Height = 41
        Caption = #1044#1086#1073#1072#1074#1080#1090#1100'/'#1054#1073#1085#1086#1074#1080#1090#1100' '#1076#1072#1085#1085#1099#1077
        TabOrder = 4
        OnClick = Button4Click
      end
      object DBLookupComboBox10: TDBLookupComboBox
        Left = 448
        Top = 168
        Width = 129
        Height = 21
        Enabled = False
        KeyField = 'firstname'
        ListField = 'firstname'
        ListSource = DataModule2.ADODS5
        TabOrder = 5
        OnCloseUp = DBLookupComboBox10Click
      end
      object DBLookupComboBox11: TDBLookupComboBox
        Left = 640
        Top = 168
        Width = 129
        Height = 21
        Enabled = False
        KeyField = 'lastname'
        ListField = 'lastname'
        ListSource = DataModule2.ADODS6
        TabOrder = 6
      end
      object DBGrid6: TDBGrid
        Left = 24
        Top = 368
        Width = 809
        Height = 120
        DataSource = DataModule2.ADODS8
        TabOrder = 7
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        Columns = <
          item
            Expanded = False
            FieldName = 'COURSE'
            Width = 194
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'NOMER_SECTION'
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'DANNYE'
            Width = 229
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'SURNAME'
            Width = 148
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'NAME'
            Width = 103
            Visible = True
          end>
      end
      object RadioButton2: TRadioButton
        Left = 264
        Top = 168
        Width = 121
        Height = 17
        Caption = #1054#1076#1080#1085' '#1089#1090#1091#1076#1077#1085#1090' '#1082#1091#1088#1089#1072
        TabOrder = 8
        OnClick = RadioButton2Click
      end
      object RadioButton1: TRadioButton
        Left = 88
        Top = 168
        Width = 121
        Height = 17
        Caption = #1042#1089#1077' '#1089#1090#1091#1076#1077#1085#1090#1099' '#1082#1091#1088#1089#1072
        Checked = True
        TabOrder = 9
        TabStop = True
        OnClick = RadioButton1Click
      end
      object ProgressBar1: TProgressBar
        Left = 528
        Top = 296
        Width = 193
        Height = 17
        Enabled = False
        ParentShowHint = False
        ShowHint = False
        TabOrder = 10
        Visible = False
      end
    end
  end
end
