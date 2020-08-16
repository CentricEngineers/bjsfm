import unittest
import numpy as np


class LoadedHoleTests(unittest.TestCase):

    def test_stresses_at_hole_boundary_with_only_px(self):
        from lekhnitskii import LoadedHole
        from tests.fortran import lekhnitskii_f as f_code
        a_inv = np.array([[2.65646e-6, -8.91007e-7, 0.], [-8.91007e-7, 2.65646e-6, 0.], [0., 0., 7.09494e-6]])
        d = 0.25
        h = 0.058
        p = 100.
        alpha = 0.
        p_stress = LoadedHole(p, d, h, a_inv)
        f_stress, f_u, f_v = f_code.loaded(4*p/h, d, a_inv, alpha, 0, 4)

        test_points = ((0.125, 0.), (0., 0.125), (-0.125, 0.), (0., -0.125))

        for i, pnt in enumerate(test_points):
            self.assertAlmostEqual(
                p_stress.stress(pnt[0], pnt[1])[0][0],
                f_stress[0][0][i],
                delta=5
            )
            self.assertAlmostEqual(
                p_stress.stress(pnt[0], pnt[1])[1][0],
                f_stress[1][0][i],
                delta=5
            )
            self.assertAlmostEqual(
                p_stress.stress(pnt[0], pnt[1])[2][0],
                f_stress[2][0][i],
                delta=5
            )


if __name__ == '__main__':
    unittest.main()
