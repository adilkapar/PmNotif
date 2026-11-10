@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'BM - Equipment Value Help'
@Search.searchable: true

define view entity ZI_PM_BM_Equipment
  as select from    I_Equipment as equip
  // NEW: Join to classification tables to get ZPM_EQ_CATEGORY value
    left outer join cabn        as charact on charact.atnam = 'ZPM_EQ_CATEGORY'

    left outer join ausp        as charVal on  charVal.objek = equip.Equipment // Equipment number (CHAR 18 vs CHAR 50 — implicit padding works)
                                           and charVal.atinn = charact.atinn // Internal char number for ZPM_EQ_CATEGORY
                                           and charVal.klart = '002'         // Class type 002 = Equipment
                                           and charVal.adzhl = '0000'        // Single-value characteristic (counter = 0)

  association [0..1] to I_EquipmentText as _Text on  $projection.EquipmentNo = _Text.Equipment
                                                 and _Text.Language          = $session.system_language

  association [0..1] to I_EquipmentData as _Data on  $projection.EquipmentNo = _Data.Equipment
                                                 and _Data.ValidityEndDate   = '99991231'


{
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['Description']
  key equip.Equipment           as EquipmentNo,

      @Search.defaultSearchElement: true
      _Text.EquipmentName       as Description,
      _Data.MaintenancePlant    as Plant,
      equip.EquipmentCategory   as EquipmentCategory,
      equip.TechnicalObjectType as TechnicalObjectType,

      // NEW: WC Category from classification characteristic ZPM_EQ_CATEGORY
      charVal.atwrt             as WCCategory
}
