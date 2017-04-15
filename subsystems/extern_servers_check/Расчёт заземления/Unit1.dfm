object Form1: TForm1
  Left = 645
  Top = 425
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = #1056#1072#1089#1095#1105#1090' '#1079#1072#1097#1080#1090#1085#1086#1075#1086' '#1079#1072#1079#1077#1084#1083#1077#1085#1080#1103
  ClientHeight = 366
  ClientWidth = 472
  Color = clBtnFace
  Font.Charset = RUSSIAN_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Courier New'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 14
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 472
    Height = 366
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = #1048#1089#1093#1086#1076#1085#1099#1077' '#1076#1072#1085#1085#1099#1077
      object Label1: TLabel
        Left = 8
        Top = 190
        Width = 245
        Height = 14
        Caption = #1053#1086#1088#1084#1072' '#1089#1086#1087#1088#1086#1090#1080#1074#1083#1077#1085#1080#1103' '#1079#1072#1079#1077#1084#1083#1077#1085#1080#1103', '#1054#1084':'
      end
      object Label10: TLabel
        Left = 8
        Top = 302
        Width = 189
        Height = 28
        Caption = #1054#1090#1085#1086#1096#1077#1085#1080#1077' '#1088#1072#1089#1089#1090#1086#1103#1085#1080#1103' '#1084#1077#1078#1076#1091' '#1079#1072#1079#1077#1084#1083#1080#1090#1077#1083#1103#1084#1080' '#1082' '#1080#1093' '#1076#1083#1080#1085#1077':'
        WordWrap = True
      end
      object Label3: TLabel
        Left = 8
        Top = 100
        Width = 168
        Height = 14
        Caption = #1044#1080#1072#1084#1077#1090#1088' '#1079#1072#1079#1077#1084#1083#1080#1090#1077#1083#1103', '#1084#1084':'
      end
      object Label4: TLabel
        Left = 8
        Top = 130
        Width = 196
        Height = 14
        Caption = #1043#1083#1091#1073#1080#1085#1072' '#1079#1072#1083#1086#1078#1077#1085#1080#1103' '#1087#1086#1083#1086#1089#1099', '#1084':'
      end
      object Label5: TLabel
        Left = 8
        Top = 160
        Width = 231
        Height = 14
        Caption = #1064#1080#1088#1080#1085#1072' '#1089#1086#1077#1076#1080#1085#1080#1090#1077#1083#1100#1085#1086#1081' '#1087#1086#1083#1086#1089#1099', '#1084#1084':'
      end
      object Label6: TLabel
        Left = 8
        Top = 70
        Width = 147
        Height = 14
        Caption = #1044#1083#1080#1085#1072' '#1079#1072#1079#1077#1084#1083#1080#1090#1077#1083#1103', '#1084':'
      end
      object Label2: TLabel
        Left = 8
        Top = 220
        Width = 308
        Height = 14
        Caption = #1057#1086#1087#1088#1086#1090#1080#1074#1083#1077#1085#1080#1077' '#1077#1089#1090#1077#1089#1090#1074#1077#1085#1085#1099#1093' '#1079#1072#1079#1077#1084#1083#1080#1090#1077#1083#1077#1081', '#1054#1084':'
      end
      object Label8: TLabel
        Left = 8
        Top = 10
        Width = 42
        Height = 14
        Caption = #1043#1088#1091#1085#1090':'
      end
      object Label9: TLabel
        Left = 8
        Top = 40
        Width = 119
        Height = 14
        Caption = #1042#1083#1072#1078#1085#1086#1089#1090#1100' '#1075#1088#1091#1085#1090#1072':'
      end
      object Edit1: TEdit
        Left = 320
        Top = 188
        Width = 137
        Height = 22
        TabOrder = 6
        Text = '0'
      end
      object GroupBox1: TGroupBox
        Left = 8
        Top = 248
        Width = 265
        Height = 49
        Caption = #1059#1076#1077#1083#1100#1085#1086#1077' '#1089#1086#1087#1088#1086#1090#1080#1074#1083#1077#1085#1080#1077' '#1075#1088#1091#1085#1090#1072', '#1054#1084'*'#1084
        TabOrder = 8
        object ComboBox3: TComboBox
          Left = 8
          Top = 20
          Width = 121
          Height = 22
          Style = csDropDownList
          ItemHeight = 14
          TabOrder = 0
          OnSelect = ComboBox3Select
          Items.Strings = (
            #1055#1077#1089#1086#1082
            #1057#1091#1087#1077#1089#1086#1082
            #1057#1091#1075#1083#1080#1085#1086#1082
            #1043#1083#1080#1085#1072
            #1063#1077#1088#1085#1086#1079#1105#1084
            #1056#1077#1095#1085#1072#1103' '#1074#1086#1076#1072
            #1052#1086#1088#1089#1082#1072#1103' '#1074#1086#1076#1072)
        end
        object Edit7: TEdit
          Left = 136
          Top = 20
          Width = 121
          Height = 22
          TabOrder = 1
          OnExit = Edit7Exit
        end
      end
      object ComboBox4: TComboBox
        Left = 208
        Top = 308
        Width = 65
        Height = 22
        Style = csDropDownList
        ItemHeight = 14
        TabOrder = 10
        Items.Strings = (
          '1'
          '2'
          '3')
      end
      object GroupBox3: TGroupBox
        Left = 280
        Top = 248
        Width = 177
        Height = 49
        Caption = #1056#1072#1079#1084#1077#1097#1077#1085#1080#1077' '#1079#1072#1079#1077#1084#1083#1080#1090#1077#1083#1077#1081
        TabOrder = 9
        object RadioButton1: TRadioButton
          Left = 8
          Top = 20
          Width = 65
          Height = 17
          Caption = #1074' '#1088#1103#1076
          TabOrder = 0
        end
        object RadioButton2: TRadioButton
          Left = 72
          Top = 20
          Width = 97
          Height = 17
          Caption = #1087#1086' '#1082#1086#1085#1090#1091#1088#1091
          TabOrder = 1
        end
      end
      object Edit4: TEdit
        Left = 320
        Top = 128
        Width = 137
        Height = 22
        TabOrder = 4
        Text = '0'
      end
      object Edit5: TEdit
        Left = 320
        Top = 158
        Width = 137
        Height = 22
        TabOrder = 5
        Text = '0'
      end
      object Edit6: TEdit
        Left = 320
        Top = 218
        Width = 137
        Height = 22
        TabOrder = 7
        Text = '0'
      end
      object Edit3: TEdit
        Left = 320
        Top = 98
        Width = 137
        Height = 22
        TabOrder = 3
        Text = '0'
      end
      object ComboBox1: TComboBox
        Left = 104
        Top = 8
        Width = 353
        Height = 22
        Style = csDropDownList
        ItemHeight = 14
        TabOrder = 0
        OnSelect = ComboBox1Select
        Items.Strings = (
          #1057#1091#1075#1083#1080#1085#1086#1082
          #1057#1072#1076#1086#1074#1072#1103' '#1079#1077#1084#1083#1103' '#1076#1086' '#1075#1083#1091#1073#1080#1085#1099' 0.6 '#1084', '#1085#1080#1078#1077' - '#1089#1083#1086#1081' '#1075#1083#1080#1085#1099
          #1043#1088#1072#1074#1080#1081' '#1089' '#1087#1088#1080#1084#1077#1089#1100#1102' '#1075#1083#1080#1085#1099', '#1085#1080#1078#1077' - '#1075#1083#1080#1085#1072
          #1048#1079#1074#1077#1089#1090#1085#1103#1082
          #1043#1088#1072#1074#1080#1081' '#1089' '#1087#1088#1080#1084#1077#1089#1100#1102' '#1087#1077#1089#1082#1072
          #1058#1086#1088#1092
          #1055#1077#1089#1086#1082
          #1043#1083#1080#1085#1072)
      end
      object ComboBox2: TComboBox
        Left = 320
        Top = 38
        Width = 137
        Height = 22
        Style = csDropDownList
        ItemHeight = 14
        TabOrder = 1
        Items.Strings = (
          #1041#1086#1083#1100#1096#1072#1103
          #1057#1088#1077#1076#1085#1103#1103
          #1057#1091#1093#1072#1103)
      end
      object Button1: TButton
        Left = 280
        Top = 304
        Width = 177
        Height = 25
        Caption = #1056#1072#1089#1089#1095#1080#1090#1072#1090#1100
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 11
        OnClick = Button1Click
      end
      object Edit2: TEdit
        Left = 320
        Top = 68
        Width = 137
        Height = 22
        TabOrder = 2
        Text = '0'
      end
    end
    object TabSheet2: TTabSheet
      Caption = #1056#1077#1079#1091#1083#1100#1090#1072#1090#1099' '#1088#1072#1089#1095#1105#1090#1072
      ImageIndex = 1
      OnShow = TabSheet2Show
      object Label7: TLabel
        Left = 8
        Top = 8
        Width = 168
        Height = 16
        Caption = #1063#1080#1089#1083#1086' '#1079#1072#1079#1077#1084#1083#1080#1090#1077#1083#1077#1081' = '
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
      end
      object Label12: TLabel
        Left = 8
        Top = 32
        Width = 264
        Height = 16
        Caption = #1056#1072#1089#1089#1090#1086#1103#1085#1080#1077' '#1084#1077#1078#1076#1091' '#1079#1072#1079#1077#1084#1083#1080#1090#1077#1083#1103#1084#1080' = '
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
      end
      object Label13: TLabel
        Left = 272
        Top = 32
        Width = 8
        Height = 16
        Caption = '0'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Courier New'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label14: TLabel
        Left = 8
        Top = 56
        Width = 120
        Height = 16
        Caption = #1044#1083#1080#1085#1072' '#1087#1086#1083#1086#1089#1099' = '
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
      end
      object Label15: TLabel
        Left = 136
        Top = 56
        Width = 8
        Height = 16
        Caption = '0'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Courier New'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label16: TLabel
        Left = 280
        Top = 32
        Width = 16
        Height = 16
        Caption = ' '#1084
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
      end
      object Label17: TLabel
        Left = 144
        Top = 56
        Width = 16
        Height = 16
        Caption = ' '#1084
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
      end
      object Label11: TLabel
        Left = 176
        Top = 8
        Width = 8
        Height = 16
        Caption = '0'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Courier New'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label18: TLabel
        Left = 8
        Top = 80
        Width = 48
        Height = 16
        Caption = #1054#1096#1080#1073#1082#1072
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clRed
        Font.Height = -13
        Font.Name = 'Courier New'
        Font.Style = [fsBold]
        ParentFont = False
        Visible = False
      end
      object Button2: TButton
        Left = 280
        Top = 304
        Width = 177
        Height = 25
        Caption = #1048#1079#1084#1077#1085#1080#1090#1100' '#1076#1072#1085#1085#1099#1077
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        OnClick = Button2Click
      end
    end
  end
end
