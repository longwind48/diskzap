use std::process::Command;

#[test]
fn version_flags_print_the_package_version_and_exit() {
    for flag in ["--version", "-V"] {
        let output = Command::new(env!("CARGO_BIN_EXE_diskzap"))
            .arg(flag)
            .output()
            .expect("diskzap should run");

        assert!(output.status.success());
        assert_eq!(
            String::from_utf8(output.stdout).unwrap(),
            format!("diskzap {}\n", env!("CARGO_PKG_VERSION"))
        );
        assert!(output.stderr.is_empty());
    }
}
