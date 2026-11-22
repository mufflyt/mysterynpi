#' NA_standards
#'
#' @description
#' Every standard assessed as not-applicable, with the reason. `srr` wants
#' these recorded in the source rather than argued in a review thread, and the
#' full assessment that produced them -- all 145 individual verdicts, with
#' counts per subsection -- is in `srr/standards-compliance.md`.
#'
#' THE SHAPE OF THIS PACKAGE, stated once so the NA verdicts below read as a
#' consequence rather than as evasion: `mysterynpi` is record-linkage
#' machinery. It decides whether two records name the same person using
#' deterministic rules. Nothing is estimated, nothing iterates to convergence,
#' there is no model object, no coefficient, no residual, no series and no
#' forecast. The standards that assume any of those are not standards this
#' package can fail; they are standards about software it is not.
#'
#' @srrstatsNA {G2.14c} G2.14c asks that missing values be replaceable with imputed ones. Refused for names: an imputed name is a fabricated identity claim, and this package exists because absence of evidence was once read as evidence of difference. Reading it as evidence of sameness is worse -- it resolves a match on a name nobody recorded. Imputation is not offered on the numeric year scale either, for the reason given at graduation_year_agreement(): imputing a year manufactures the compatibility the function is asked to judge.
#' @srrstatsNA {G2.5} No argument is ever expected to be a factor: the API is
#'   character-and-data.frame. A factor column arriving in a tabular input is
#'   converted to its labels by `read_name_column()`, which says so.
#' @srrstatsNA {G3.1} No covariance calculation exists anywhere in the package.
#' @srrstatsNA {G4.0} Nothing writes a user-named local file. Results are
#'   returned as objects; the DuckDB backend writes into a connection the
#'   caller supplies and names.
#' @srrstatsNA {G5.6} Parameter recovery has no referent: there are no
#'   parameters. Every rule is a decision function whose output is one of three
#'   named verdicts.
#'
#' @srrstatsNA {EA5.0} The package produces no graphical output, so there is no
#'   graphical accessibility to assess. The two base `barplot()` calls in
#'   `vignette("end-to-end-nppes-matching")` are the vignette's, not the
#'   package's.
#' @srrstatsNA {EA5.1} No typeface is specified anywhere, because nothing is
#'   drawn.
#' @srrstatsNA {EA5.4} No visualisation whose values could be rounded.
#' @srrstatsNA {EA5.5} No axes, so no units on them.
#' @srrstatsNA {EA5.6} No bundled visualisation library.
#' @srrstatsNA {EA6.1} No graphical output for `vdiffr` or equivalent to
#'   compare.
#'
#' @srrstatsNA {RE1.2} No predictor variables: the inputs are name fields and
#'   identifiers.
#' @srrstatsNA {RE1.4} No distributional assumptions are made. The rules are
#'   deterministic and documented individually.
#' @srrstatsNA {RE2.2} There is no response variable to distinguish from
#'   predictors.
#' @srrstatsNA {RE2.3} Centring and scaling are undefined for name tokens.
#' @srrstatsNA {RE2.4} Perfect collinearity has no analogue in agreement rules.
#' @srrstatsNA {RE3.0} Nothing iterates to convergence, so nothing can fail to
#'   converge.
#' @srrstatsNA {RE3.1} No convergence messages exist to suppress.
#' @srrstatsNA {RE3.2} No convergence thresholds exist to default.
#' @srrstatsNA {RE3.3} No convergence thresholds exist to set.
#' @srrstatsNA {RE4.1} No model object, so none can be constructed without
#'   fitting.
#' @srrstatsNA {RE4.2} No coefficients.
#' @srrstatsNA {RE4.3} No coefficients, so no intervals on them.
#' @srrstatsNA {RE4.4} No model specification to return.
#' @srrstatsNA {RE4.6} No parameters, so no variance-covariance matrix.
#' @srrstatsNA {RE4.7} No convergence statistics.
#' @srrstatsNA {RE4.8} No response variable.
#' @srrstatsNA {RE4.9} No modelled values.
#' @srrstatsNA {RE4.10} No residuals: a match decision has no error term.
#' @srrstatsNA {RE4.12} The transformations are deliberately not invertible. A
#'   name key loses information on purpose; an inverse would be a fabrication.
#' @srrstatsNA {RE4.13} No predictor metadata.
#' @srrstatsNA {RE4.14} Nothing is extrapolated or forecast.
#' @srrstatsNA {RE4.15} No forecast errors or intervals.
#' @srrstatsNA {RE4.16} No categorical-group response modelling.
#' @srrstatsNA {RE6.1} No non-generic default plot to document.
#' @srrstatsNA {RE6.2} No fitted values to plot.
#' @srrstatsNA {RE6.3} No `predict()` method, so no forecast plot.
#' @srrstatsNA {RE7.3} No accessor methods on a model object to exercise.
#' @srrstatsNA {RE7.4} No forecast errors or intervals to confirm.
#'
#' @srrstatsNA {TS1.3} No time-series pre-processing routine, because no
#'   function accepts a series.
#' @srrstatsNA {TS1.4} No time or date components to maintain: a graduation
#'   year arrives as an integer on a roster row.
#' @srrstatsNA {TS1.5} No ordering index exists.
#' @srrstatsNA {TS1.6} No ordering to violate.
#' @srrstatsNA {TS1.7} The `units` package has no role in name agreement.
#' @srrstatsNA {TS2.0} Regular data is neither presumed nor required; rows are
#'   unordered.
#' @srrstatsNA {TS2.2} Stationarity of moments has no analogue in a name key.
#' @srrstatsNA {TS2.3} No stationarity assumptions to document.
#' @srrstatsNA {TS2.4} No stationarity checks to implement.
#' @srrstatsNA {TS2.5} No row or column ordering tied to a series.
#' @srrstatsNA {TS2.6} No auto-covariance matrices.
#' @srrstatsNA {TS3.0} Nothing forecasts, so there is no horizon over which
#'   errors could widen.
#' @srrstatsNA {TS3.1} No forecast to violate the previous standard.
#' @srrstatsNA {TS3.2} No forecast error drivers to document.
#' @srrstatsNA {TS3.3} No forecast horizons.
#' @srrstatsNA {TS4.0} Return values are match decisions, not series.
#' @srrstatsNA {TS4.1} No input units to carry through.
#' @srrstatsNA {TS4.3} No units or time scales in the returns.
#' @srrstatsNA {TS4.4} No transformations affecting forecast moments.
#' @srrstatsNA {TS4.5} No forecast confidence intervals.
#' @srrstatsNA {TS4.6} Nothing enables forecasting.
#' @srrstatsNA {TS4.7} No modelled-versus-observed distinction to make.
#' @srrstatsNA {TS5.1} No temporal axis.
#' @srrstatsNA {TS5.2} No time variable to place on an axis.
#' @srrstatsNA {TS5.3} No index units to print.
#' @srrstatsNA {TS5.4} No frequency domain.
#' @srrstatsNA {TS5.5} No lines, broken or continuous.
#' @srrstatsNA {TS5.6} No forecast distribution to bound.
#' @srrstatsNA {TS5.7} No model and forecast values to show together.
#' @srrstatsNA {TS5.8} No model/forecast distinction to visualise.
#'
#' @srrstatsNA {EA2.4} An explicit relational class system (the standard names `dm`) across a 123-export API whose contract is "you name the columns, we never guess" would be a different package rather than an increment on this one.
#' @srrstatsNA {EA5.0a} No graphical output exists, so there is no colour perception to accommodate.
#' @srrstatsNA {EA5.0b} No graphical output exists, so there is no contrast or scaling to choose.
#' @srrstatsNA {RE1.0} There is no model to specify. A formula interface over a function that takes two character vectors would tell a reader the package fits something it does not.
#' @srrstatsNA {RE1.1} No formula interface, therefore no formula-to-matrix conversion to document.
#' @srrstatsNA {RE2.4a} Perfect collinearity between predictors has no analogue: there are no predictors.
#' @srrstatsNA {RE2.4b} Perfect collinearity between a response and a predictor has no analogue: there is no response.
#' @srrstatsNA {RE4.0} No model object. Inventing one would imply a fitted statistical model where there is a deterministic decision function.
#' @srrstatsNA {RE4.17} A print method for a model object that does not exist; the match result has its own print method (EA4.2).
#' @srrstatsNA {RE4.18} A summary method for a model object that does not exist; the match result has its own summary method (EA3.0).
#' @srrstatsNA {RE6.0} No model object to dispatch a default plot on, and a plot of a match table is a choice about which counts matter -- the caller's, not the package's.
#' @srrstatsNA {G3.1a} No covariance calculation exists, so there is no algorithm choice to expose.
#' @srrstatsNA {G5.6a} Parameter recovery has no referent: there are no parameters to recover.
#' @srrstatsNA {G5.6b} No parameter estimates, so no tolerance on their recovery.
#' @srrstatsNA {TS1.0} There is no time series. Adopting `ts`/`xts`/`tsibble` would require inventing a temporal dimension the data does not have.
#' @srrstatsNA {TS1.2} Validating time-series classes presupposes accepting them.
#' @srrstatsNA {TS2.1a} Missing-value handling is offered through `na_action` (G2.14), but error-on-missing for a *series* has no referent here.
#' @srrstatsNA {TS2.1b} No series in which to warn about imputed values.
#' @srrstatsNA {TS2.1c} No series in which to impute; see the NA_standards note on G2.14c.
#' @srrstatsNA {TS2.4a} No stationarity to check, so nothing to warn about.
#' @srrstatsNA {TS2.4b} No stationarity to check, so nothing to transform.
#' @srrstatsNA {TS3.3a} No forecast errors to report.
#' @srrstatsNA {TS3.3b} No forecast errors to document the absence of.
#' @srrstatsNA {TS4.0a} Return values are match decisions, not series, so they carry no time index.
#' @srrstatsNA {TS4.0b} No series to return in a time-series class.
#' @srrstatsNA {TS4.5a} No forecast, so no distribution to return.
#' @srrstatsNA {TS4.5b} No forecast, so no quantiles to return.
#' @srrstatsNA {TS4.5c} No forecast, so no standard errors to return.
#' @srrstatsNA {TS4.6a} Nothing forecasts, so there is no forecast object to return.
#' @srrstatsNA {TS4.6b} Nothing forecasts, so there are no forecast values to label.
#' @srrstatsNA {TS4.6c} Nothing forecasts, so there is no forecast horizon to record.
#' @srrstatsNA {TS4.7a} No modelled values to distinguish from observed ones.
#' @srrstatsNA {TS4.7b} No forecast values to distinguish from input values.
#' @srrstatsNA {TS4.7c} No distinction to document, because neither side of it exists.
#' @srrstatsNA {TS5.0} No class system, so no default plot method; a plot of a match table is not a time-series plot.
#'
#' @name NA_standards
#' @keywords internal
NULL
