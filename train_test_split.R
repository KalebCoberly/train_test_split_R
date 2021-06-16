library(tidyverse)
library(container)
# library(comprehenr)

train_test_split = function(df, y_cols, id_cols, feats_lst,
                            test_size = .3, alpha = .5, target_alpha = .9) {
  # Splits df into train/test sets and input/target (X/y) sets.
    # (Must have id_col, but can be "dummy" since it's discarded for index.)
  # Parameters:
    # df: (data.frame) Full data set, including target variable(s).
    # y_cols: (c(character)) Target column(s).
    # id_cols: (c(character)) Id column(s) to drop, because df maintains index.
    # test_size: (numeric) Proportion of rows to use for test set.
      # (Does not validate.)
  # Return:
    # split_lst: (list(data.frame)) (train_X, train_y, test_X, test_y)
      # train_X (data.frame) Input features in training subset.
      # train_y (data.frame) Target variable in training subset.
      # test_X (data.frame) Input features in testing subset.
      # test_y (data.frame) Target variable in testing subset.
  
  split_lst = list(
    'train_X' = data.frame(),
    'train_y' = data.frame(),
    'test_X' = data.frame(),
    'test_y' = data.frame()
  )
  
  full_set_len = nrow(df)
  test_set_len = as.integer(test_size * full_set_len)
  
###
### TO DO: Add a parameter and logic to choose whether to track this. ###
###
  # To track average p-values of features:
  feats_p_av_lst = vector(mode = 'list', length = length(feats_lst))
  names(feats_p_av_lst) = feats_lst
  
  
  valid_split = FALSE
  while (!valid_split) {
    # Split.
    test_idx = sample(x = full_set_len, size = test_set_len)
    split_lst$train_X = select(df[-test_idx, ], -all_of(y_cols))
    split_lst$train_y = select(df[-test_idx, ], all_of(y_cols))
    split_lst$train_y[id_cols] = split_lst$train_X[id_cols]
    split_lst$test_X = select(df[test_idx, ], -all_of(y_cols))
    split_lst$test_y = select(df[test_idx, ], all_of(y_cols))
    split_lst$test_y[id_cols] = split_lst$test_X[id_cols]
    rm(df)
    
    # Validate the split.
    # Randomize test order to "cost-average" compute.
    # But, test y separately to avoid the join compute and data copies.
    feats_lst = sample(feats_lst)
    # y_feats_lst = to_list(
    #   for (feat in feats_lst)
    #     if (feat %in% colnames(split_lst$train_y))
    #       feat
    # )
    
    y_validation_results = validate_split(
      train = split_lst$train_y,
      test = split_lst$test_y,
      # feats_lst = y_feats_lst,
      feats_lst = feats_lst,
      y_cols = y_cols,
      feats_p_val_lst = feats_p_av_lst,
      alpha = alpha,
      target_alpha = target_alpha
    )
    feats_p_av_lst = y_validation_results$p_vals
    
    if (y_validation_results$valid){
      X_feats_lst = to_list(
        for (feat in feats_lst)
          if (feat %in% colnames(split_lst$train_X))
            feat
      )
      X_validation_results = validate_split(
        train = split_lst$train_X,
        test = split_lst$test_X,
        feats_lst = X_feats_lst,
        y_cols = y_cols,
        feats_p_val_lst = feats_p_av_lst,
        alpha = alpha,
        target_alpha = target_alpha
      )
      feats_p_av_lst = X_validation_results$p_vals
      if (X_validation_results$valid) {
        valid_split = TRUE
      } # else { print("Invalid split. Resampling.") }
    } # else { print("Invalid split. Resampling.") }
  }
  
  for(feat in names(feats_p_av_lst)) {
    feats_p_av_lst[[feat]] = mean(feats_p_av_lst[[feat]])
  }
  # print('Average p-values:')
  # print(feats_p_av_lst)
  
  return(split_lst)
}


validate_split = function(train, test, feats_lst, y_cols, feats_p_val_lst,
                          alpha = .5, target_alpha = .9) {
  # Conducts Wilcoxon ranks sum test column by column to test if train and test
    # represent a similar superset. (i.e., is the split stratified on every
    # feature?) Both train and test should have the same features. There should
    # be at least one numeric (i.e. continuous) feature, as the test will only
    # be performed on these columns -- this does limit the test.
  # Parameters:
    # train: (data.frame) A subset of original set to compare to the other
      # subset, test.
    # test: (data.frame) A subset of original set to compare to the other
      # subset, train.
    # feats_lst: (list(character)) List of features to test.
    # y_cols: (c(character)) Vector of target features.
    # feats_p_val_lst: (list(character:list(double)) Dictionary of p-values to
      # to track which features are hardest to stratify.
    # alpha: (numeric) Probability of incorrectly rejecting the null hypothesis.
      # H0 = feature n of train and test does not represent different sets.
        # (i.e. representative split)
      # H1 = feature n of train and test represents a different superset.
    # target_alpha: (numeric) Alpha to use if feature is target feature (i.e.
      # if feature is in y_cols).
  # Return:
    # list(valid: (bool), p_vals: (list(character:list(double)))
      # valid: (bool) Are the sets representative of the same superset?
    # p_vals: (list(character:list(double)) feats_p_val_lst updated
  
  valid = TRUE
  
  for (feat in feats_lst) {
    if (valid & feat %in% colnames(train) & feat %in% colnames(test)) {
      this_alpha = alpha
      if (feat %in% y_cols) {
        this_alpha = target_alpha
      }
      results = wilcox.test(
        x = as.double(train[[feat]]),
        y = as.double(test[[feat]])
      )
      if (!(results$p.value > this_alpha)) {
        # print("Reject null hypothesis that split is not unrepresentative:")
        valid = FALSE
      }
      # print(feat)
      # print(results$p.value)
      feats_p_val_lst[[feat]] = c(feats_p_val_lst[[feat]], results$p.value)
    }
  }
  
  return(list('valid' = valid, 'p_vals' = feats_p_val_lst))
}


write_sets = function(set_lst, prefix, file_path, row.names = FALSE) {
  for (set_name in names(set_lst)) {
    write.csv(
      set_lst[[set_name]],
      paste(file_path, prefix, set_name, '.csv', sep = ''),
      row.names = row.names
    )
  }
}
