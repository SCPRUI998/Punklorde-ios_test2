# 超星学习通

~~学习通本质Webview~~

学习通的代码非常陈旧（~~文物级别的，建议上交国家~~），学习通也是一个MPA（M到不能再M那种，他就连一个最基本的搜索框，都要分成至少两个Page，导致性能奇差无比），所以在App中加一个Webview，就可以把学习通搞进来了。

由于JS强大的动态性，我们可以非常容易地往Webview界面注入用户脚本。因此，实现了学习通的mod功能。

~~Minecraft都能打Mod，为什么学习通不能？~~

现在Punklorde的学习通Mod Runtime是基于子项目[StudyWolf](https://github.com/zrurf/StudyWolf)的，其定义了学习通的Mod API规范，以及实现了一个学习通的Mod Runtime。

## 鸣谢
感谢 [course_helper](https://bgithub.xyz/AneryCoft/course_helper)及其相关项目和贡献者提供的API和做作的逆向工作。
感谢 [qintaiyang](https://github.com/qintaiyang/PassChaoxing)的逆向和反混淆工作。
