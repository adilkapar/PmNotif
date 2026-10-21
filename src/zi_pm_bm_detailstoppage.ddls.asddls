@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'BM - Detail Stoppage Codes'

define view entity ZI_PM_BM_DetailStoppage
  as select distinct from zpm_stop_config as cfg

  left outer join qpct as detail_cat_text
    on detail_cat_text.katalogart = 'C'
   and detail_cat_text.codegruppe = cfg.detail_code_grp
   and detail_cat_text.code       = cfg.detail_code
   and detail_cat_text.sprache    = $session.system_language

{
  key cfg.plant            as Plant,
  key cfg.basic_code_grp   as BasicCodeGroup,
  key cfg.basic_code       as BasicCode,
  key cfg.detail_code_grp  as DetailCodeGroup,
  @ObjectModel.text.element: ['DetailStoppageText']
  @UI.textArrangement: #TEXT_LAST
  key cfg.detail_code      as DetailCode,

      @Semantics.text: true
      detail_cat_text.kurztext as DetailStoppageText
}
where cfg.active = 'X'
