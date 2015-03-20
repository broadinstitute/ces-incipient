from urllib.parse import urlparse
import subprocess
import sys
import argparse

def log(message):
    print("[TRANSFER]", message)
    sys.stdout.flush()

def transfer_file(src, dest, p12_path, p12_password, google_email, aws_access_key, aws_secret_key, aria2_connections):
    parsed_url = urlparse(src)
    if parsed_url.scheme.lower() in ['gs', 'file', '']:
        transfer_cmd = base_gsutil_command(p12_path, p12_password, google_email, aws_access_key, aws_secret_key)
        transfer_cmd.extend(["-m", "cp", src, dest])
    elif parsed_url.scheme.lower() in ['http', 'https']:
        # NOTE: Aria2c automatically handles resuming failed or interrupted downloads.

        # TODO: We might want to set --file-allocation=falloc (defaults to prealloc).  Aria2c tries to pre-allocate
        # the entire contents of the file before it starts downloading it.  The manual says prealloc can be slow
        # with large file sizes but falloc only works on certain file systems.

        transfer_cmd = ['aria2c', '-x', str(aria2_connections), '-s', str(aria2_connections), src, '--out', dest]
    else:
        raise Exception("Unsupported scheme in src [%s]" % src)
    log('Running: ' + ' '.join([str(x) for x in transfer_cmd]))
    return_code = subprocess.call(transfer_cmd)
    if return_code != 0:
        raise Exception("Non-zero return code ({0}) while running [{1}]".format(return_code, transfer_cmd))

def base_gsutil_command(p12_path, p12_password, google_email, aws_access_key, aws_secret_key):
    cmd = [
        "gsutil",
        "-o", "Boto:https_validate_certificates=True",
        "-o", "GSUtil:content_language=en",
        "-o", "GSUtil:default_api_version=2",
        "-o", "GSUtil:check_hashes=if_fast_else_skip"
    ]
    if google_email is not None: cmd.extend(["-o", "Credentials:gs_service_client_id=" + google_email])
    if p12_path is not None: cmd.extend(["-o", "Credentials:gs_service_key_file=" + p12_path])
    if p12_password is not None: cmd.extend(["-o", "Credentials:gs_service_key_file_password=" + p12_password])
    if aws_access_key is not None: cmd.extend(["-o", "Credentials:aws_access_key_id=" + aws_access_key])
    if aws_secret_key is not None: cmd.extend(["-o", "Credentials:aws_secret_access_key=" + aws_secret_key])
    return cmd

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("src", help="the URL/path of the object/file to transfer")
    parser.add_argument("dest", help="the URL/path of the destination of the object/file")
    parser.add_argument("--google-p12", help="Local path to google credentials (p12 file)")
    parser.add_argument("--google-p12-password", help="Password for google p12 file")
    parser.add_argument("--google-p12-email", help="Email address for service account associated to google p12 file")
    parser.add_argument("--aws-access-key", help="Amazon Web Service access key, for transfering to/from")
    parser.add_argument("--aws-secret-key", help="Amazon Web Service secret key")
    parser.add_argument("--aria2-connections", type=int, default=5, help="Aria2 max connectiosn per host.  Can range from 1-16.  Passed as the -x parameter to aria2c")
    args = parser.parse_args()
    transfer_file(args.src, args.dest, args.google_p12, args.google_p12_password, args.google_p12_email, args.aws_access_key, args.aws_secret_key, args.aria2_connections)

if __name__ == "__main__":
    main()

