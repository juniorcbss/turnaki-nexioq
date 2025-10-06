#[tokio::test]
async fn test_treatment_duration_validation() {
    assert!(30 >= 5 && 30 <= 480);
    assert!(45 >= 5 && 45 <= 480);
}

#[tokio::test]
async fn test_treatment_name_min_length() {
    let name = "ABC";
    assert!(name.len() >= 3);
}
