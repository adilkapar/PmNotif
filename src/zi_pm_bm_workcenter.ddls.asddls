@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'BM - Work Center Value Help'

define view entity ZI_PM_BM_WorkCenter
  as select from I_WorkCenter as wc
  left outer join I_WorkCenterText as wctxt
    on wc.WorkCenterInternalID = wctxt.WorkCenterInternalID
    and wctxt.Language = $session.system_language
{
  @ObjectModel.text.element: ['Description']
  key wc.WorkCenterInternalID   as WorkCenterID,  
      wc.WorkCenter             as WorkCenter,     
      wctxt.WorkCenterText      as Description,    
      wc.Plant                  as Plant,           
      wc.WorkCenterCategoryCode as WorkCenterCategory 
}
//where wc.WorkCenterCategoryCode = '0005'