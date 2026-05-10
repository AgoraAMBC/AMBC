import { api } from './api.js';

export const DashboardService = {
  resumo() {
    return api.get('/dashboard/resumo.php');
  },
};
