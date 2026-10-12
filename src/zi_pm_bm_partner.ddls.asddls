@AccessControl.authorizationCheck: #NOT_REQUIRED -- Changed to NOT_REQUIRED to prevent DCL dump if no roles exist
@EndUserText.label: 'BM - User Responsible (VU) Value Help'
@Search.searchable: true
-- REMOVED: @ObjectModel.resultSet.sizeCategory: #XS (To force a popup window instead of a dropdown)

define view entity ZI_PM_BM_Partner
  as select from    I_User
    inner join usr21 on usr21.bname = I_User.UserID
    inner join adcp  on  adcp.addrnumber = usr21.addrnumber
                     and adcp.persnumber = usr21.persnumber
{
      @UI.lineItem: [{ position: 10 }]
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['FullName']
  key I_User.UserID          as Partner,

      @UI.lineItem: [{ position: 20 }]
      @Search.defaultSearchElement: true
      I_User.UserDescription as FullName
}
where
      I_User.UserID    is not initial
  and adcp.department  = 'MAINTENANCE TECHNICIAN'