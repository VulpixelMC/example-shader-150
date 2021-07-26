float fogify(float x, float w) {
	return w / (x * x + w);
}
