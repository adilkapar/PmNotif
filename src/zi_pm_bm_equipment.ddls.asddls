@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'BM - Equipment Value Help'
@Search.searchable: true

define view entity ZI_PM_BM_Equipment
  as select from I_Equipment as equip
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
      //      equip.Plant               as Plant,
      _Data.MaintenancePlant    as Plant,
      equip.EquipmentCategory   as EquipmentCategory,
      equip.TechnicalObjectType as TechnicalObjectType
}