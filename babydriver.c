#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/string.h>

#define DEVICE_NAME "babyioctl"
#define BABY_IOCTL_MAGIC 0xBA
#define BABY_IOCTL_SET_SIZE _IOW(BABY_IOCTL_MAGIC, 0, size_t)
#define BABY_IOCTL_READ _IOW(BABY_IOCTL_MAGIC, 1, struct baby_req)

struct baby_req {
	char __user *buf;
};

struct baby_blob {
	char note[0x40];
	char flag[0x40];
};

static struct baby_blob g_blob;
static size_t g_read_size = sizeof(g_blob.note);
static char flag_value[sizeof(g_blob.flag)] = "flag{local_bundle_placeholder}";
module_param_string(flag_value, flag_value, sizeof(flag_value), 0000);

static long baby_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
	size_t user_size;
	struct baby_req req;

	switch (cmd) {
	case BABY_IOCTL_SET_SIZE:
		if (copy_from_user(&user_size, (void __user *)arg, sizeof(user_size)))
			return -EFAULT;

		/*
		 * Vulnerability:
		 * The driver trusts a user-controlled size and never checks
		 * whether it exceeds note[].
		 */
		g_read_size = user_size;
		return 0;

	case BABY_IOCTL_READ:
		if (copy_from_user(&req, (void __user *)arg, sizeof(req)))
			return -EFAULT;

		if (copy_to_user(req.buf, g_blob.note, g_read_size))
			return -EFAULT;

		return 0;

	default:
		return -EINVAL;
	}
}

static const struct file_operations baby_fops = {
	.owner = THIS_MODULE,
	.unlocked_ioctl = baby_ioctl,
};

static struct miscdevice baby_dev = {
	.minor = MISC_DYNAMIC_MINOR,
	.name = DEVICE_NAME,
	.fops = &baby_fops,
	.mode = 0600,
};

static int __init baby_init(void)
{
	int ret;

	memset(&g_blob, 'A', sizeof(g_blob));
	memcpy(g_blob.note, "Baby's first kernel leak. Read more than 0x40 bytes.",
	       51);
	strscpy(g_blob.flag, flag_value, sizeof(g_blob.flag));

	ret = misc_register(&baby_dev);
	if (ret)
		return ret;

	pr_info("babyioctl: loaded, /dev/%s is ready\n", DEVICE_NAME);
	return 0;
}

static void __exit baby_exit(void)
{
	misc_deregister(&baby_dev);
	pr_info("babyioctl: unloaded\n");
}

module_init(baby_init);
module_exit(baby_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Codex");
MODULE_DESCRIPTION("Beginner-friendly ioctl OOB read challenge");
